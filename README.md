# Self-Hosted Infrastructure

A comprehensive infrastructure-as-code setup for self-hosting essential services including databases, monitoring, security, and productivity tools.

## 🏗️ Architecture Overview

This repository contains Docker Compose configurations and documentation for deploying a complete self-hosted infrastructure stack, including:

- **Database Services**: MongoDB, PostgreSQL, Redis
- **Monitoring & Observability**: Comprehensive monitoring stack with metrics, logs, and alerting
- **Security**: Fail2ban for intrusion prevention, Infisical for secrets management
- **Storage & Productivity**: MinIO object storage, Nextcloud file sharing
- **Container Management**: Docker monitoring and management tools

## 📁 Repository Structure

```
├── docker-monitoring/    # Container monitoring and management
├── docs/                # Documentation and setup guides
├── fail2ban/            # Intrusion prevention and security
├── infisical/           # Secrets management
├── minio/               # Object storage service
├── mlflow/              # ML experiment tracking (if applicable)
├── mongodb/             # MongoDB database
├── monitoring-stack/    # Metrics, logging, and alerting
├── nextcloud/           # File sharing and collaboration
├── postgres/            # PostgreSQL database
└── redis/               # In-memory data store
```

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Minimum 4GB RAM, 20GB storage
- Domain name (recommended for SSL/TLS)

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd self-hosted-infrastructure
   ```

2. **Copy environment templates**
   ```bash
   find . -name "*.env.example" -exec bash -c 'cp "$1" "${1%.example}"' _ {} \;
   ```

3. **Configure environment variables**
   Edit the `.env` files in each service directory with your specific settings.

4. **Start core services**
   ```bash
   # Start databases first
   docker-compose -f postgres/docker-compose.yml up -d
   docker-compose -f mongodb/docker-compose.yml up -d
   docker-compose -f redis/docker-compose.yml up -d
   
   # Start monitoring stack
   docker-compose -f monitoring-stack/docker-compose.yml up -d
   
   # Start remaining services
   docker-compose -f nextcloud/docker-compose.yml up -d
   docker-compose -f minio/docker-compose.yml up -d
   ```

## 🔧 Service Configuration

### Database Services

- **PostgreSQL**: Primary relational database
- **MongoDB**: Document database for flexible schemas
- **Redis**: Caching and session storage

### Monitoring Stack

Complete observability solution including:
- Metrics collection and visualization
- Log aggregation and analysis
- Alerting and notification system
- Performance monitoring dashboards

### Security & Access

- **Fail2ban**: Automated intrusion prevention
- **Infisical**: Centralized secrets management
- **SSL/TLS**: Automated certificate management (recommended with reverse proxy)

### Storage & Collaboration

- **MinIO**: S3-compatible object storage
- **Nextcloud**: File sharing, calendar, and collaboration platform

## 🛡️ Security Considerations

1. **Change default passwords** in all `.env` files
2. **Enable firewall** and close unnecessary ports
3. **Set up SSL/TLS** certificates for web services
4. **Configure backup strategies** for persistent data
5. **Review and customize Fail2ban** rules for your environment
6. **Use strong secrets** managed through Infisical

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs -f [service-name]

# Monitor resource usage
docker stats
```

### Backup Strategy

Each service directory contains backup scripts and documentation. Key backup locations:
- Database dumps: `./backups/databases/`
- Configuration files: `./backups/configs/`
- User data: `./backups/data/`

### Updates

```bash
# Update images
docker-compose pull

# Restart services with new images
docker-compose up -d
```

## 🔗 Service Access

After deployment, services will be available at:

- **Nextcloud**: `http://localhost:8080` (configure your domain)
- **MinIO Console**: `http://localhost:9001`
- **Monitoring Dashboard**: `http://localhost:3000`
- **Database connections**: See individual service documentation

> **Note**: Configure a reverse proxy (nginx, Traefik) for production deployments with proper SSL/TLS termination.

## 📚 Documentation

Detailed setup guides and configuration documentation are available in the `docs/` directory:

- Service-specific setup instructions
- Troubleshooting guides
- Performance optimization tips
- Security hardening recommendations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

Please ensure all changes include appropriate documentation updates.

## 📄 License

[MIT License](LICENSE.md)

## ⚠️ Disclaimer

This infrastructure setup is intended for self-hosting enthusiasts and small to medium deployments. Always review configurations, implement proper security measures, and maintain regular backups before using in production environments.

## 🆘 Support

- Check the `docs/` directory for detailed guides
- Review service logs for troubleshooting
- Open an issue for bugs or feature requests
---

**Happy self-hosting! 🏠**

**Configs managed, developed and created by Shaivil Patel**