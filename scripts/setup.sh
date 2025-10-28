#!/bin/bash

# MobyDock Setup Script
# This script sets up the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Docker is installed
check_docker() {
    print_header "Checking Docker Installation"

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi

    print_success "Docker and Docker Compose are installed"

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi

    print_success "Docker is running"
}

# Check system requirements
check_requirements() {
    print_header "Checking System Requirements"

    # Check available memory
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        MEMORY=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    else
        # Linux
        MEMORY=$(free -g | awk '/^Mem:/{print $2}')
    fi

    if [ "$MEMORY" -lt 4 ]; then
        print_warning "System has less than 4GB of RAM. Some services may not work properly."
    else
        print_success "System has sufficient memory (${MEMORY}GB)"
    fi

    # Check available disk space
    DISK_SPACE=$(df . | tail -1 | awk '{print $4}')
    DISK_SPACE_GB=$((DISK_SPACE / 1024 / 1024))

    if [ "$DISK_SPACE_GB" -lt 10 ]; then
        print_warning "System has less than 10GB of free disk space. Consider cleaning up."
    else
        print_success "System has sufficient disk space (${DISK_SPACE_GB}GB free)"
    fi
}

# Setup directories
setup_directories() {
    print_header "Setting Up Directories"

    directories=("data" "logs" "backups" "init-scripts/mariadb" "init-scripts/postgres" "init-scripts/mongo")

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        else
            print_success "Directory already exists: $dir"
        fi
    done
}

# Setup environment file
setup_environment() {
    print_header "Setting Up Environment"

    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
            print_warning "Please review and update the .env file with your preferred settings"
        else
            print_warning ".env.example file not found. Creating basic .env file"
            cat > .env << EOF
# Environment variables for Docker development environment

# MariaDB
MARIADB_ROOT_PASSWORD=your-secure-root-password
MARIADB_USER=dev
MARIADB_PASSWORD=dev123
MARIADB_DATABASE=app_db

# PostgreSQL
POSTGRES_PASSWORD=your-secure-postgres-password
POSTGRES_USER=dev
POSTGRES_DB=app_db

# MongoDB
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=your-secure-mongo-password
MONGO_INITDB_DATABASE=app_db

# Portainer
PORTAINER_PASSWORD=your-portainer-password

# pgAdmin
PGADMIN_DEFAULT_EMAIL=dev@example.com
PGADMIN_DEFAULT_PASSWORD=your-pgadmin-password
EOF
            print_success "Created basic .env file"
            print_warning "Please review and update the .env file with your preferred settings"
        fi
    else
        print_success ".env file already exists"
    fi
}

# Setup Docker network
setup_network() {
    print_header "Setting Up Docker Network"

    if ! docker network ls | grep -q "mobydock_dev-network"; then
        docker network create mobydock_dev-network 2>/dev/null || docker network create dev-network
        print_success "Created Docker network"
    else
        print_success "Docker network already exists"
    fi
}

# Start services
start_services() {
    print_header "Starting Services"

    echo "Starting core services..."
    if docker-compose up -d; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        exit 1
    fi

    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 10
}

# Show status
show_status() {
    print_header "Service Status"

    docker-compose ps

    print_header "Access URLs"
    echo "📊 Adminer (Database Management): http://localhost:8080"
    echo "🐘 pgAdmin (PostgreSQL): http://localhost:5050"
    echo "🍃 MongoDB Express: http://localhost:8081"
    echo "🔴 Redis Commander: http://localhost:8082"
    echo "📧 MailHog (Email Testing): http://localhost:8025"
    echo "🐳 Portainer (Docker Management): http://localhost:9000"
    echo ""
    print_header "Database Credentials"
    echo "🔹 MariaDB: dev/dev123"
    echo "🔹 PostgreSQL: dev/dev123"
    echo "🔹 MongoDB: root/password (change in .env)"
    echo "🔹 Redis: no password (by default)"
    echo ""
    print_success "Setup completed successfully!"
    echo ""
    echo "Useful commands:"
    echo "  make logs          - View service logs"
    echo "  make health        - Check service health"
    echo "  make shell-mariadb - Access MariaDB shell"
    echo "  make shell-postgres - Access PostgreSQL shell"
    echo "  make shell-mongo   - Access MongoDB shell"
    echo "  make down          - Stop all services"
}

# Main setup function
main() {
    print_header "MobyDock Development Environment Setup"

    check_docker
    check_requirements
    setup_directories
    setup_environment
    setup_network
    start_services
    show_status
}

# Run main function
main "$@"