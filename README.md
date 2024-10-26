# Servonaut 🚀

Servonaut is a one-click deployment solution for Nuxt.js applications on Ubuntu/Debian servers. It automatically sets up and configures all necessary components for a production-ready environment.

## Features

### 🌐 Web Server

- Caddy server with automatic SSL
- HTTP/2 support
- Automatic HTTPS
- Zero-downtime deployments

### 🔄 CI/CD

- GitHub webhook integration
- Automatic deployments
- Zero-downtime updates

### 🗄️ Database

- PostgreSQL setup with SSL
- Secure remote access configuration
- Automatic password generation
- Easy credential management

### 🛡️ Security

- Automated server hardening
- Fail2ban for brute-force protection
- CrowdSec for advanced threat detection
- UFW firewall configuration
- Secure SSH setup
- Automatic security updates
- System-level security configurations

## Prerequisites

- A fresh Ubuntu/Debian server (ARM64)
- Root access
- A domain name pointing to your server's IP
- GitHub repository with your Nuxt.js project

## Installation

1. SSH into your server as root
2. Clone the repository: `git clone https://github.com/michaelsieminski/servonaut.git`
3. Install servonaut: `cd servonaut && sudo bash ./install.sh`
4. Run `servonaut setup` to begin the setup process

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License

## Support

For issues and feature requests, please open an issue on GitHub.
