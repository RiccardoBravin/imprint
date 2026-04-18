#!/bin/bash

# Logging functions
function log_info() {
    echo -e "[\e[1;94mINFO\e[0m] $*"
}

function log_warn() {
    echo -e "[\e[1;93mWARN\e[0m] $*"
}

function log_error() {
    echo -e "[\e[1;91mERROR\e[0m] $*"
}

function fail() {
    log_error "$*"
    exit 1
}

# Log start of script execution
log_info "Script execution started"

# Log flutter project creation
log_info "Creating flutter project..."
flutter create --project-name='imprint' --description='A structured document editor where templates are defined in code and content is filled at runtime, with export to PDF, cloud, and print.' .

log_info "Script execution completed successfully."
