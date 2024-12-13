#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Global variables
# -----------------------------
ARCH_TARGET=""
VERBOSE=0
DRYRUN=0
JSONLOG=0
CLEAN=0
INC_VERSION=0
CONFIG_FILE="./config/config.json"

# -----------------------------
# Utility functions
# -----------------------------
timestamp() {
    date -Iseconds
}

usage() {
    cat <<EOF
Usage: $0 -t <target> [options]

Options:
  -t, --target <name>   Build target (required)
  -c, --clean           Clean before building
  --inc                 Increment build number after successful build
  -v, --verbose         Enable verbose output
  --dry-run             Show actions without executing them
  --json-log            Output logs in JSON format
  -h, --help            Show this help message
EOF
}

log() {
    if [[ $JSONLOG -eq 1 ]]; then
        json_log "info" "$1"
    else
        echo "[LOG] $1"
    fi
}

dry() {
    if [[ $JSONLOG -eq 1 ]]; then
        json_log "dryrun" "$1"
    else
        echo "[DRY-RUN] $1"
    fi
}

json_log() {
    local level="$1"
    local msg="$2"
    local ts
    ts=$(timestamp)

    printf '{"timestamp":"%s","level":"%s","target":"%s","message":"%s"}\n' \
        "$ts" "$level" "$ARCH_TARGET" "$msg"
}

run() {
    local cmd="$*"

    if [[ $DRYRUN -eq 1 ]]; then
        dry "Would run: $cmd"
    else
        if [[ $JSONLOG -eq 1 ]]; then
            json_log "exec" "Running: $cmd"
        else
            [[ $VERBOSE -eq 1 ]] && echo "[EXEC] $cmd"
        fi
        eval "$cmd"
    fi
}

# -----------------------------
# Auto-increment build number
# -----------------------------
increment_build_number() {
    local current
    current=$(jq -r ".version.build_number" "$CONFIG_FILE")
    local next=$((current + 1))

    jq ".version.build_number = $next" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    log "Incremented build number: $current → $next"
}

# -----------------------------
# Clean pipeline
# -----------------------------
clean_pipeline() {
    log "Cleaning build artifacts for target: $ARCH_TARGET"

    local build_dir
    build_dir=$(jq -r ".build_dir" "$CONFIG_FILE")

    export BUILD_DIR="$build_dir"
    export ARCH="$ARCH_TARGET"

    run "make clean"
}

# -----------------------------
# Build pipeline
# -----------------------------
build_pipeline() {
    log "Loading configuration for target: $ARCH_TARGET"

    local arch_json
    arch_json=$(jq -r ".architectures.\"$ARCH_TARGET\"" "$CONFIG_FILE")

    local tool
    tool=$(echo "$arch_json" | jq -r ".toolchain.tool")

    local cflags ldflags
    cflags=$(echo "$arch_json" | jq -r ".cflags")
    ldflags=$(echo "$arch_json" | jq -r ".ldflags")

    local build_dir build_name_prefix
    build_dir=$(jq -r ".build_dir" "$CONFIG_FILE")
    build_name_prefix=$(jq -r ".build_name_prefix" "$CONFIG_FILE")

    local major minor build
    major=$(jq -r ".version.major" "$CONFIG_FILE")
    minor=$(jq -r ".version.minor" "$CONFIG_FILE")
    build=$(jq -r ".version.build_number" "$CONFIG_FILE")

    local build_target_name
    build_target_name="${build_name_prefix}_${ARCH_TARGET}_v${major}.${minor}.${build}"

    export CC="${tool}gcc"
    export AS="${tool}as"
    export SIZE="${tool}size"
    export CFLAGS="$cflags"
    export LDFLAGS="$ldflags"
    export BUILD_DIR="$build_dir"
    export ARCH="$ARCH_TARGET"
    export TARGET="$build_target_name"

    log "Toolchain prefix: $tool"
    log "CFLAGS: $CFLAGS"
    log "LDFLAGS: $LDFLAGS"
    log "BUILD_DIR: $BUILD_DIR"
    log "ARCH: $ARCH_TARGET"
    log "TARGET: $TARGET"

    run "make"
    READELF=${tool}readelf
    $READELF -l -S $BUILD_DIR/$ARCH/$TARGET
}

# -----------------------------
# Argument parsing
# -----------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--target)
                ARCH_TARGET="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN=1
                shift
                ;;
            --inc)
                INC_VERSION=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            --dry-run)
                DRYRUN=1
                shift
                ;;
            --json-log)
                JSONLOG=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
    done
}

# -----------------------------
# Main function (Python style)
# -----------------------------
main() {
    parse_args "$@"

    if [[ -z "$ARCH_TARGET" ]]; then
        echo "Error: -t <target> is required" >&2
        usage
        exit 1
    fi

    if ! jq -e ".architectures.\"$ARCH_TARGET\"" "$CONFIG_FILE" >/dev/null; then
        echo "Error: Invalid target '$ARCH_TARGET'" >&2
        echo "Available targets:" >&2
        jq -r ".architectures | keys[]" "$CONFIG_FILE" >&2
        usage
        exit 1
    fi

    if [[ $DRYRUN -eq 1 ]]; then
        log "Dry-run mode enabled"
    fi

    if [[ $JSONLOG -eq 1 ]]; then
        json_log "info" "JSON log mode enabled"
    fi

    if [[ $CLEAN -eq 1 ]]; then
        clean_pipeline
    fi

    build_pipeline

    if [[ $INC_VERSION -eq 1 && $DRYRUN -eq 0 ]]; then
        increment_build_number
    fi
}

# -----------------------------
# Entry point
# -----------------------------
main "$@"
