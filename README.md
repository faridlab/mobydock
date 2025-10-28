# MobyDock - Modern Docker Development Environment

A comprehensive, production-ready Docker development environment with the latest services and development tools. Perfect for rapid application development, testing, and deployment.

## 🚀 Features

### Core Services
- **MariaDB 11.4** - Latest MariaDB with UTF8MB4 support
- **PostgreSQL 16** - Modern PostgreSQL with useful extensions
- **MongoDB 7.0** - Latest MongoDB with authentication
- **Redis 7.2** - High-performance Redis with custom config
- **Portainer CE** - Docker management interface
- **MailHog** - Email testing and debugging

### Development Tools
- **Adminer** - Universal database management
- **pgAdmin 4** - PostgreSQL administration
- **MongoDB Express** - MongoDB web interface
- **Redis Commander** - Redis management interface
- **Optional Services** (via profiles):
  - Node.js development environment
  - PHP/Apache development
  - Nginx reverse proxy
  - RabbitMQ message queue
  - Elasticsearch + Kibana
  - Jaeger tracing
  - Seq logging

## 📋 Prerequisites

- Docker >= 20.10
- Docker Compose >= 2.0
- Make (optional, for convenient commands)
- 4GB+ RAM recommended

## 🛠 Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd mobydock
make install
```

### 2. Start Services
```bash
# Start core services
make up

# Or with Docker Compose
docker-compose up -d
```

### 3. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Adminer | http://localhost:8080 | mariadb: dev/dev123 |
| pgAdmin | http://localhost:5050 | dev@example.com / admin123 |
| MongoDB Express | http://localhost:8081 | dev/dev123 |
| Redis Commander | http://localhost:8082 | - |
| MailHog | http://localhost:8025 | - |
| Portainer | http://localhost:9000 | Setup on first visit |

### Database Connections

#### MariaDB
- **Host:** localhost
- **Port:** 3306
- **User:** dev
- **Password:** dev123
- **Database:** app_db

#### PostgreSQL
- **Host:** localhost
- **Port:** 5432
- **User:** dev
- **Password:** dev123
- **Database:** app_db

#### MongoDB
- **Host:** localhost
- **Port:** 27017
- **User:** root
- **Password:** password (change in .env)
- **Database:** app_db

#### Redis
- **Host:** localhost
- **Port:** 6379
- **Password:** (none by default)

## 🎯 Usage

### Basic Commands (with Make)
```bash
# Start all services
make up

# Stop all services
make down

# View logs
make logs

# Access service shells
make shell-mariadb
make shell-postgres
make shell-mongo
make shell-redis

# Database backup/restore
make db-backup
make db-restore

# Check service health
make health
make status
```

### Docker Compose Commands
```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f

# Execute commands
docker-compose exec mariadb mysql -u root -ppassword
docker-compose exec postgres psql -U dev -d app_db
docker-compose exec mongo mongosh -u root -p password
docker-compose exec redis redis-cli
```

### Development Profiles
```bash
# Start with Node.js development
make up-node

# Start with monitoring tools
make up-monitoring

# Start with search tools
make up-search

# Start with message queue
make up-queue

# Start with admin tools
make up-admin
```

## 🔧 Configuration

### Environment Variables
Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Key variables to customize:
- Database passwords
- Service credentials
- Network settings
- Resource limits

### Custom Configurations
- **Redis:** `redis.conf` - Redis server configuration
- **Database init:** `init-scripts/` - Database initialization scripts
- **Dev services:** `docker-compose.dev.yml` - Additional development services

## 📊 Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Adminer       │    │   pgAdmin       │    │ MongoDB Express │
│   (8080)        │    │   (5050)        │    │   (8081)        │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MariaDB       │    │   PostgreSQL    │    │   MongoDB       │
│   (3306)        │    │   (5432)        │    │   (27017)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Redis         │    │   MailHog       │    │   Portainer     │
│   (6379)        │    │   (8025)        │    │   (9000)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🗂 Project Structure

```
mobydock/
├── docker-compose.yml              # Main services
├── docker-compose.dev.yml          # Development services
├── redis.conf                      # Redis configuration
├── Makefile                        # Convenience commands
├── README.md                       # This file
├── .env.example                    # Environment template
├── init-scripts/                   # Database initialization
│   ├── mariadb/
│   ├── postgres/
│   └── mongo/
├── data/                           # Data storage (auto-created)
├── logs/                           # Log files (auto-created)
└── backups/                        # Database backups (auto-created)
```

## 🔒 Security Considerations

- **Default credentials** are for development only
- **Change all passwords** before production use
- **Network isolation** via custom Docker network
- **No exposed services** except development ports
- **SSL/TLS** should be added for production

## 📈 Performance Tuning

### Resource Limits
- Redis: 256MB memory limit
- MongoDB: 3GB minimum recommended
- PostgreSQL: 1GB minimum recommended
- Mariaadb: 1GB minimum recommended

### Optimization Tips
1. Use Docker volumes for persistence
2. Configure proper memory limits
3. Monitor resource usage with `make status`
4. Regular database backups with `make db-backup`

## 🐛 Troubleshooting

### Common Issues

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :3306,5432,27017,6379,9000

# Change ports in docker-compose.yml
```

**Permission issues:**
```bash
# Fix Docker permissions
sudo chown -R $USER:$USER ./data ./logs ./backups
```

**Service won't start:**
```bash
# Check logs
docker-compose logs [service-name]

# Rebuild without cache
docker-compose build --no-cache
```

**Memory issues:**
```bash
# Increase Docker memory limits
# Check available memory
docker system df
```

### Reset Environment
```bash
# Complete reset
make uninstall

# Start fresh
make install
```

## 🚀 Production Deployment

### Security Checklist
- [ ] Change all default passwords
- [ ] Enable SSL/TLS
- [ ] Configure firewalls
- [ ] Set up monitoring
- [ ] Backup strategy
- [ ] Update configurations

### Scaling
- Use Docker Swarm or Kubernetes
- Configure load balancers
- Set up database replication
- Implement caching strategies

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Useful Links

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/documentation)

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Search existing issues
3. Create a new issue with detailed information

---

**Happy Developing! 🎉**