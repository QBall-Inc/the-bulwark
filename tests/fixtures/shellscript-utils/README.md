# Shell Script Utilities

A collection of shell utilities for common DevOps tasks.

## Scripts

- `bin/backup.sh` - Backup files to specified location
- `bin/deploy.sh` - Deploy application to target environment

## Usage

```bash
./bin/backup.sh /source/path /backup/path
./bin/deploy.sh production
```

## Requirements

- Bash 4.0+
- rsync
- ssh
