class S3Config {
  const S3Config({
    required this.endpoint,
    required this.bucket,
    required this.accessKey,
    required this.secretKey,
  });

  final String endpoint;
  final String bucket;
  final String accessKey;
  final String secretKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is S3Config &&
          endpoint == other.endpoint &&
          bucket == other.bucket &&
          accessKey == other.accessKey &&
          secretKey == other.secretKey;

  @override
  int get hashCode => Object.hash(endpoint, bucket, accessKey, secretKey);

  S3Config copyWith({
    String? endpoint,
    String? bucket,
    String? accessKey,
    String? secretKey,
  }) => S3Config(
    endpoint: endpoint ?? this.endpoint,
    bucket: bucket ?? this.bucket,
    accessKey: accessKey ?? this.accessKey,
    secretKey: secretKey ?? this.secretKey,
  );
}
