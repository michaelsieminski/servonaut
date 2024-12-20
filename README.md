![Servonaut Banner](./public/banner.jpg)

## Servonaut

A zero-config deployment solution for js web applications. Deploy your app to production in minutes, not days.

### Features

- **Zero Configuration** - One command to set up your entire production environment
- **Battle-tested Stack** - Web Server, SSL, Database, Caching, and more
- **Framework Agnostic** - Works with most web frameworks
- **Production Ready** - SSL, security, and performance optimized out of the box
- **Auto Deploy** - Push to main, deploy to production
- **Secure by Default** - Comprehensive security measures without the complexity
- **Environment Variables** - Easily manage environment variables
- **Flexible** - Automatically detects your web framework and builds around it
- **Lightweight** - No bloat, just what is really needed in production

---

### Prerequisites

- Ubuntu/Debian server (arm or x86) (we recommend [Hetzner](https://www.hetzner.com/cloud/))
- A domain name pointing to your server's IP
- Root SSH access to your server

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/michaelsieminski/servonaut.git

# 2. Install Servonaut
cd servonaut && sudo bash ./install.sh

# 3. Run setup
servonaut setup
```

### Commands

```bash
servonaut help - Shows all available commands
servonaut update - Updates Servonaut to the latest version
servonaut setup - Sets up your production environment
servonaut env list - Lists all environment variables
servonaut env add - Adds an environment variable
servonaut env del - Deletes an environment variable
servonaut status - Checks the status of your deployment
```

---

### Contributing

We welcome contributions to improve Servonaut. Please feel free to create an issue or submit a pull request.

### License

Servonaut is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
