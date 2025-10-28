# Deploy - Infrastructure & Custom Files

This folder contains **all non-Moodle core files**: deployment configuration, documentation, and project-specific content. Everything custom to this project is isolated here.

## Structure

```
deploy/
├── docker/          # Docker & deployment configuration
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   ├── docker-entrypoint.sh
│   ├── nginx.conf
│   ├── .dockerignore
│   └── .env.example
├── docs/            # Deployment documentation
│   ├── DOCKER.md
│   └── DEV_SETUP.md
└── custom/          # Project-specific custom files
```

## Quick Start

### Development

```bash
# From project root
docker-compose -f deploy/docker/docker-compose.dev.yml --env-file .env.dev up -d
```

Access at http://localhost:8080

### Production

```bash
# From project root
docker-compose -f deploy/docker/docker-compose.yml --env-file .env up -d
```

## Documentation

- **[DEV_SETUP.md](docs/DEV_SETUP.md)** - Development environment setup and troubleshooting
- **[DOCKER.md](docs/DOCKER.md)** - Docker architecture, Coolify deployment, and performance optimization

## Philosophy

**This folder contains ONLY custom infrastructure code.** The root of the repository maintains the standard Moodle structure (MOODLE_501_STABLE). This approach:

✅ Makes Moodle upgrades conflict-free  
✅ Clearly separates infrastructure from application code  
✅ Keeps deployment configuration organized in one place  
✅ Preserves the official Moodle file structure
