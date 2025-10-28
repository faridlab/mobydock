#!/bin/bash

# MobyDock Backup Script
# This script creates backups of all databases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=7

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if containers are running
check_containers() {
    print_header "Checking Running Containers"

    containers=("mariadb" "postgres" "mongo")
    running=true

    for container in "${containers[@]}"; do
        if docker-compose ps $container | grep -q "Up"; then
            print_success "$container is running"
        else
            print_warning "$container is not running, skipping backup"
            running=false
        fi
    done

    if [ "$running" = false ]; then
        print_warning "Some services are not running. Only backing up running services."
    fi
}

# Create backup directory
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_success "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup MariaDB
backup_mariadb() {
    if docker-compose ps mariadb | grep -q "Up"; then
        print_header "Backing up MariaDB"

        backup_file="$BACKUP_DIR/mariadb_backup_$TIMESTAMP.sql"

        if docker-compose exec -T mariadb mysqldump \
            -u root \
            -p${MARIADB_ROOT_PASSWORD:-password} \
            --single-transaction \
            --routines \
            --triggers \
            --all-databases > "$backup_file"; then
            print_success "MariaDB backup created: $backup_file"

            # Compress backup
            gzip "$backup_file"
            print_success "MariaDB backup compressed: $backup_file.gz"
        else
            print_error "Failed to backup MariaDB"
        fi
    fi
}

# Backup PostgreSQL
backup_postgres() {
    if docker-compose ps postgres | grep -q "Up"; then
        print_header "Backing up PostgreSQL"

        backup_file="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"

        if docker-compose exec -T postgres pg_dump \
            -U ${POSTGRES_USER:-dev} \
            -d ${POSTGRES_DB:-app_db} \
            --no-password \
            --verbose \
            --clean \
            --no-acl \
            --no-owner > "$backup_file"; then
            print_success "PostgreSQL backup created: $backup_file"

            # Compress backup
            gzip "$backup_file"
            print_success "PostgreSQL backup compressed: $backup_file.gz"
        else
            print_error "Failed to backup PostgreSQL"
        fi
    fi
}

# Backup MongoDB
backup_mongodb() {
    if docker-compose ps mongo | grep -q "Up"; then
        print_header "Backing up MongoDB"

        backup_dir="$BACKUP_DIR/mongodb_backup_$TIMESTAMP"

        if docker-compose exec -T mongo mongodump \
            --uri="mongodb://${MONGO_INITDB_ROOT_USERNAME:-root}:${MONGO_INITDB_ROOT_PASSWORD:-password}@localhost:27017" \
            --out="/tmp/mongodb_backup_$TIMESTAMP"; then

            # Copy backup from container
            docker cp mongo:/tmp/mongodb_backup_$TIMESTAMP "$BACKUP_DIR/mongodb_backup_$TIMESTAMP"

            # Clean up container backup
            docker-compose exec -T mongo rm -rf "/tmp/mongodb_backup_$TIMESTAMP"

            # Create tar archive
            tar -czf "$backup_dir.tar.gz" -C "$BACKUP_DIR" "mongodb_backup_$TIMESTAMP"
            rm -rf "$backup_dir"

            print_success "MongoDB backup created: $backup_dir.tar.gz"
        else
            print_error "Failed to backup MongoDB"
        fi
    fi
}

# Backup Redis (optional)
backup_redis() {
    if docker-compose ps redis | grep -q "Up"; then
        print_header "Backing up Redis"

        backup_file="$BACKUP_DIR/redis_backup_$TIMESTAMP.rdb"

        if docker-compose exec -T redis redis-cli BGSAVE; then
            # Wait for background save to complete
            sleep 5

            if docker cp redis:/data/dump.rdb "$backup_file"; then
                print_success "Redis backup created: $backup_file"

                # Compress backup
                gzip "$backup_file"
                print_success "Redis backup compressed: $backup_file.gz"
            else
                print_error "Failed to copy Redis backup"
            fi
        else
            print_error "Failed to backup Redis"
        fi
    fi
}

# Clean old backups
clean_old_backups() {
    print_header "Cleaning Old Backups"

    # Remove backups older than RETENTION_DAYS
    find "$BACKUP_DIR" -name "*backup_*.gz" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "*backup_*.sql" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "*backup_*.rdb" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "mongodb_backup_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +

    print_success "Cleaned backups older than $RETENTION_DAYS days"
}

# Show backup summary
show_summary() {
    print_header "Backup Summary"

    echo "Backup location: $BACKUP_DIR"
    echo "Backup timestamp: $TIMESTAMP"
    echo ""
    echo "Created backups:"
    ls -la "$BACKUP_DIR"/*backup_$TIMESTAMP* 2>/dev/null || echo "No backups created"
    echo ""
    echo "Backup retention: $RETENTION_DAYS days"
    echo ""
    print_success "Backup process completed!"
}

# Main backup function
main() {
    print_header "MobyDock Database Backup"

    check_containers
    create_backup_dir
    backup_mariadb
    backup_postgres
    backup_mongodb
    backup_redis
    clean_old_backups
    show_summary
}

# Run main function
main "$@"