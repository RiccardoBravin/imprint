import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:imprint/data/models/s3_config.dart';

typedef S3Result = ({bool ok, String message});

class S3Service {
  S3Service._();

  static const _algorithm = 'AWS4-HMAC-SHA256';
  static const _service = 's3';

  static Future<S3Result> testConnection(S3Config config) async {
    try {
      final ep = _Endpoint.parse(config.endpoint);
      final now = DateTime.now().toUtc();
      // GET with max-keys=0 instead of HEAD: returns an XML body on errors so
      // we can surface the actual S3 error code rather than just a status number.
      final uri = ep.buildUri('/${config.bucket}', query: 'list-type=2&max-keys=0');
      final headers = _signedHeaders(
        method: 'GET',
        uri: uri,
        ep: ep,
        bodyBytes: const [],
        extraHeaders: {},
        config: config,
        now: now,
      );
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return (ok: true, message: 'Connected — bucket "${config.bucket}" found.');
      }
      final s3Err = _parseS3Error(response.body);
      final detail = s3Err != null ? '$s3Err\n' : '';
      final urlHint = 'URL tried: $uri';
      if (response.statusCode == 404) {
        return (ok: false, message: 'Bucket "${config.bucket}" not found.\n$detail$urlHint');
      }
      if (response.statusCode == 403) {
        return (ok: false, message: 'Access denied — check your access key, secret, and bucket permissions.\n$detail$urlHint');
      }
      return (ok: false, message: 'Server returned ${response.statusCode}.\n$detail$urlHint');
    } catch (e) {
      return (ok: false, message: _friendlyError(e));
    }
  }

  static Future<S3Result> upload(
    S3Config config,
    Uint8List bytes,
    String objectName,
  ) async {
    try {
      final ep = _Endpoint.parse(config.endpoint);
      final now = DateTime.now().toUtc();
      final uri = ep.buildUri('/${config.bucket}/$objectName');
      final headers = _signedHeaders(
        method: 'PUT',
        uri: uri,
        ep: ep,
        bodyBytes: bytes,
        extraHeaders: {'content-type': 'application/pdf'},
        config: config,
        now: now,
      );
      final response = await http.put(uri, headers: headers, body: bytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final url = _presignedUrl(
          config: config,
          ep: ep,
          objectName: objectName,
          expiresSecs: 3600,
          now: now,
        );
        return (ok: true, message: url);
      }
      return (ok: false, message: 'Upload failed (${response.statusCode}).');
    } catch (e) {
      return (ok: false, message: _friendlyError(e));
    }
  }

  // ---------------------------------------------------------------------------

  static Map<String, String> _signedHeaders({
    required String method,
    required Uri uri,
    required _Endpoint ep,
    required List<int> bodyBytes,
    required Map<String, String> extraHeaders,
    required S3Config config,
    required DateTime now,
  }) {
    final dateStamp = _date(now);
    final amzDate = _dateTime(now);
    final payloadHash = _hexHash(bodyBytes);

    final headers = <String, String>{
      'host': ep.hostHeader,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      ...extraHeaders.map((k, v) => MapEntry(k.toLowerCase(), v)),
    };

    final sortedKeys = headers.keys.toList()..sort();
    final canonicalHeaders = sortedKeys.map((k) => '$k:${headers[k]}\n').join();
    final signedHeaders = sortedKeys.join(';');

    final canonicalRequest = [
      method,
      uri.path,
      uri.query,
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/${ep.region}/$_service/aws4_request';
    final stringToSign = [
      _algorithm,
      amzDate,
      credentialScope,
      _hexHash(utf8.encode(canonicalRequest)),
    ].join('\n');

    final signature = _hex(
      _hmac(_signingKey(config.secretKey, dateStamp, ep.region), utf8.encode(stringToSign)),
    );

    return {
      ...headers,
      'authorization': '$_algorithm Credential=${config.accessKey}/$credentialScope, '
          'SignedHeaders=$signedHeaders, Signature=$signature',
    };
  }

  static String _presignedUrl({
    required S3Config config,
    required _Endpoint ep,
    required String objectName,
    required int expiresSecs,
    required DateTime now,
  }) {
    final dateStamp = _date(now);
    final amzDate = _dateTime(now);
    final credentialScope = '$dateStamp/${ep.region}/$_service/aws4_request';
    final path = '/${config.bucket}/$objectName';

    final queryParams = [
      ('X-Amz-Algorithm', _algorithm),
      ('X-Amz-Credential', Uri.encodeComponent('${config.accessKey}/$credentialScope')),
      ('X-Amz-Date', amzDate),
      ('X-Amz-Expires', '$expiresSecs'),
      ('X-Amz-SignedHeaders', 'host'),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final queryString = queryParams.map((e) => '${e.$1}=${e.$2}').join('&');

    final canonicalRequest = [
      'GET',
      path,
      queryString,
      'host:${ep.hostHeader}\n',
      'host',
      'UNSIGNED-PAYLOAD',
    ].join('\n');

    final stringToSign = [
      _algorithm,
      amzDate,
      credentialScope,
      _hexHash(utf8.encode(canonicalRequest)),
    ].join('\n');

    final signature = _hex(
      _hmac(_signingKey(config.secretKey, dateStamp, ep.region), utf8.encode(stringToSign)),
    );

    return '${ep.scheme}://${ep.hostHeader}$path?$queryString&X-Amz-Signature=$signature';
  }

  // ---------------------------------------------------------------------------

  static List<int> _signingKey(String secretKey, String dateStamp, String region) {
    final kDate = _hmac(utf8.encode('AWS4$secretKey'), utf8.encode(dateStamp));
    final kRegion = _hmac(kDate, utf8.encode(region));
    final kService = _hmac(kRegion, utf8.encode(_service));
    return _hmac(kService, utf8.encode('aws4_request'));
  }

  static List<int> _hmac(List<int> key, List<int> data) =>
      Hmac(sha256, key).convert(data).bytes;

  static String _hexHash(List<int> bytes) => _hex(sha256.convert(bytes).bytes);

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String _date(DateTime dt) =>
      dt.year.toString().padLeft(4, '0') +
      dt.month.toString().padLeft(2, '0') +
      dt.day.toString().padLeft(2, '0');

  static String _dateTime(DateTime dt) =>
      '${_date(dt)}T'
      '${dt.hour.toString().padLeft(2, '0')}'
      '${dt.minute.toString().padLeft(2, '0')}'
      '${dt.second.toString().padLeft(2, '0')}Z';

  static String? _parseS3Error(String body) {
    if (body.isEmpty) return null;
    final code = RegExp(r'<Code>(.*?)</Code>').firstMatch(body)?.group(1);
    final msg = RegExp(r'<Message>(.*?)</Message>').firstMatch(body)?.group(1);
    if (code == null && msg == null) return null;
    return [?code, ?msg].join(': ');
  }

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'Cannot reach the endpoint. Check the URL and your network.';
    }
    if (msg.contains('403') || msg.contains('AccessDenied')) {
      return 'Access denied. Check your access key and secret.';
    }
    if (msg.contains('NoSuchBucket')) {
      return 'Bucket not found.';
    }
    return msg.replaceFirst(RegExp(r'^[A-Za-z]+Exception: '), '');
  }
}

class _Endpoint {
  const _Endpoint({
    required this.host,
    required this.port,
    required this.useSSL,
    required this.isDefaultPort,
  });

  factory _Endpoint.parse(String raw) {
    final normalised = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.parse(normalised);
    final useSSL = uri.scheme != 'http';
    final port = uri.hasPort ? uri.port : (useSSL ? 443 : 80);
    final isDefault = (useSSL && port == 443) || (!useSSL && port == 80);
    return _Endpoint(
      host: uri.host.isEmpty ? raw : uri.host,
      port: port,
      useSSL: useSSL,
      isDefaultPort: isDefault,
    );
  }

  final String host;
  final int port;
  final bool useSSL;
  final bool isDefaultPort;

  String get scheme => useSSL ? 'https' : 'http';
  String get hostHeader => isDefaultPort ? host : '$host:$port';
  String get region => host.endsWith('.r2.cloudflarestorage.com') ? 'auto' : 'us-east-1';

  Uri buildUri(String path, {String? query}) => Uri(
        scheme: scheme,
        host: host,
        port: isDefaultPort ? null : port,
        path: path,
        query: query,
      );
}
