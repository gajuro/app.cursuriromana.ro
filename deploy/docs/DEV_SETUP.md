# Development Setup Guide

## Quick Start

### 1. Start Development Environment

```bash
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d
```

### 2. Access Services

- **Moodle**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081 (DB management)
- **Redis Commander**: http://localhost:8082 (Cache management)

### 3. View Logs

```bash
# All services
docker-compose -f docker-compose.dev.yml logs -f

# Specific service
docker-compose -f docker-compose.dev.yml logs -f web
docker-compose -f docker-compose.dev.yml logs -f db
docker-compose -f docker-compose.dev.yml logs -f redis
```

## Key Differences from Production

| Feature | Dev | Production |
|---------|-----|-----------|
| **Port** | 8080 | 80 |
| **DB Port** | 3307 | 3306 (internal) |
| **Memory Limit** | 512M | 256M |
| **Execution Time** | 600s | 300s |
| **Code Mounting** | ✅ Hot-reload | ❌ Copied |
| **phpMyAdmin** | ✅ Included | ❌ Not included |
| **Redis Commander** | ✅ Included | ❌ Not included |
| **Debug Mode** | ✅ Enabled | ❌ Disabled |

## Common Commands

### Start Services
```bash
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d
```

### Stop Services
```bash
docker-compose -f docker-compose.dev.yml down
```

### Rebuild Images
```bash
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d --build
```

### Access Container Shell
```bash
docker-compose -f docker-compose.dev.yml exec web bash
```

### Run Moodle CLI Commands
```bash
docker-compose -f docker-compose.dev.yml exec web php admin/cli/maintenance.php --enable
docker-compose -f docker-compose.dev.yml exec web php admin/cli/maintenance.php --disable
```

### Clear Caches
```bash
docker-compose -f docker-compose.dev.yml exec web php admin/cli/purge_caches.php
```

### Database Access
```bash
# Via phpMyAdmin: http://localhost:8081
# Or via command line:
docker-compose -f docker-compose.dev.yml exec db mysql -u moodle -p moodle
# Password: dev_password
```

### Redis Access
```bash
# Via Redis Commander: http://localhost:8082
# Or via CLI:
docker-compose -f docker-compose.dev.yml exec redis redis-cli
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose -f docker-compose.dev.yml logs web

# Rebuild
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d --build
```

### Database connection errors
```bash
# Verify database is healthy
docker-compose -f docker-compose.dev.yml ps

# Check database logs
docker-compose -f docker-compose.dev.yml logs db
```

### Permission issues
```bash
# Fix file permissions
docker-compose -f docker-compose.dev.yml exec web chown -R www-data:www-data /var/www/html
```

### Clear everything and start fresh
```bash
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d --build
```

## Important Notes

### Moodle Installer - Web Address
When running the Moodle installer, it will suggest `http://localhost` as the web address. **You must change this to `http://localhost:8080`** to match your development setup. This ensures CSS, JavaScript, and other resources load correctly.

### CSS/JS Not Loading
If CSS or JavaScript files fail to load (404 errors), it's likely because the wwwroot is set incorrectly. Verify it's set to `http://localhost:8080` in the installer or in the Moodle admin settings.

## Development Tips

1. **Code Changes**: Edit files locally, they'll reflect immediately in the container
2. **Database**: Use phpMyAdmin at http://localhost:8081 for visual management
3. **Cache**: Use Redis Commander at http://localhost:8082 to inspect cache
4. **Logs**: Always check container logs when something goes wrong
5. **Performance**: Development environment has higher memory limits for better debugging

## Environment Variables

Edit `.env.dev` to customize:
- `APP_PORT`: Web server port (default: 8080)
- `DB_PASSWORD`: Database password
- `ADMIN_PASSWORD`: Moodle admin password
- `PHP_MEMORY_LIMIT`: PHP memory limit
- `PHP_MAX_EXECUTION_TIME`: PHP execution timeout

## Production Deployment

When ready for production, use the standard `docker-compose.yml`:
```bash
docker-compose --env-file .env up -d
```

Ensure you've updated `.env` with secure credentials before deploying.
