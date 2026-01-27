#!/bin/bash
set -euo pipefail

SOURCE_DIR="${1:-}"
BACKUP_DIR="${2:-}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -z "$SOURCE_DIR" ] || [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <source_dir> <backup_dir>"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

echo "Creating backup of $SOURCE_DIR..."
tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

echo "Backup created: $BACKUP_PATH"
echo "Size: $(du -h "$BACKUP_PATH" | cut -f1)"
