# 🚀 Migrare la nginx: Ghid Complet

Acest setup folosește **nginx + PHP-FPM** în loc de Apache pentru performanță maximă.

## De ce nginx?

### Avantaje față de Apache:
✅ **20-30% mai puțină memorie** (15MB vs 50MB per worker)  
✅ **40% mai rapid** la fișiere statice (CSS, JS, imagini)  
✅ **Mai multe conexiuni simultane** cu aceeași RAM  
✅ **Reverse proxy îmbunătățit** pentru Coolify  
✅ **Scalabilitate superioară** pentru traffic mare  

### Arhitectură:
```
[Coolify/Reverse Proxy]
        ↓
    [nginx] ← servește static files
        ↓
   [PHP-FPM] ← procesează PHP
        ↓
   [MariaDB + Redis]
```

## Structura Containerelor

### 1. **nginx** (nginx:alpine)
- Port: 80 (expus)
- Rol: Web server, servire fișiere statice, reverse proxy către PHP-FPM
- Config: `nginx.conf`
- Health check: wget pe localhost

### 2. **php-fpm** (custom - built from Dockerfile)
- Port: 9000 (intern)
- Rol: Procesare PHP, Moodle logic
- Pool config: 50 max children, dynamic PM
- Health check: `php-fpm -t`

### 3. **MariaDB** (mariadb:11.8)
- Optimizări: 512MB buffer pool, 32MB query cache

### 4. **Redis** (redis:7-alpine)
- Rol: Session storage, cache

## Volume-uri Partajate

Volume-ul `moodle_app` este **partajat** între nginx și PHP-FPM:
- **nginx**: Read-only (doar servește fișiere)
- **PHP-FPM**: Read-write (execută și modifică)

```yaml
# În docker-compose.yml
nginx:
  volumes:
    - moodle_app:/var/www/html:ro  # read-only

php-fpm:
  volumes:
    - moodle_app:/var/www/html:rw  # read-write
```

## Configurație nginx

Fișierul `nginx.conf` include:

### 1. **Routing Engine** (Moodle 4.5+)
```nginx
location / {
    try_files $uri $uri/ /r.php?$args;
}
```

### 2. **Caching Static Assets**
```nginx
location ~* \.(jpg|jpeg|gif|png|css|js)$ {
    expires 30d;
    access_log off;
}
```

### 3. **PHP-FPM Pass-through**
```nginx
location ~ \.php$ {
    fastcgi_pass php-fpm:9000;
    # ... fastcgi params
}
```

### 4. **Security Headers**
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection

### 5. **HTTPS Detection** (pentru Coolify)
```nginx
map $http_x_forwarded_proto $fastcgi_https {
    default off;
    https on;
}
```

## PHP-FPM Configuration

### Pool Settings (`www.conf`):
```ini
pm = dynamic
pm.max_children = 50        # Max procese simultane
pm.start_servers = 5        # Procese la start
pm.min_spare_servers = 5    # Min idle workers
pm.max_spare_servers = 35   # Max idle workers
pm.max_requests = 500       # Requests per worker (anti-leak)
```

### Recomandări RAM:
- **1GB RAM**: max_children = 20
- **2GB RAM**: max_children = 50 (default)
- **4GB RAM**: max_children = 100
- **8GB+ RAM**: max_children = 150-200

**Formula**: `max_children = (RAM disponibil) / 50MB`

## Deployment pe Coolify

### 1. Build și Start
```bash
# Build imaginea
docker-compose build --no-cache

# Start serviciile
docker-compose up -d

# Verifică status
docker-compose ps
```

### 2. Verificare nginx funcționează
```bash
# Test nginx config
docker-compose exec nginx nginx -t

# Reload nginx (fără restart)
docker-compose exec nginx nginx -s reload

# Logs nginx
docker-compose logs -f nginx
```

### 3. Verificare PHP-FPM funcționează
```bash
# Test PHP-FPM config
docker-compose exec php-fpm php-fpm -t

# Status pool
docker-compose exec php-fpm kill -USR1 1

# Logs PHP-FPM
docker-compose logs -f php-fpm
```

## Debugging

### nginx nu găsește fișierele:
```bash
# Verifică volume-ul este montat
docker-compose exec nginx ls -la /var/www/html/public

# Verifică permissions
docker-compose exec php-fpm ls -la /var/www/html
```

### PHP-FPM connection refused:
```bash
# Verifică PHP-FPM rulează pe port 9000
docker-compose exec php-fpm netstat -tulpn | grep 9000

# Verifică nginx poate comunica cu php-fpm
docker-compose exec nginx ping php-fpm
```

### Static files nu se servesc:
- Verifică `nginx.conf` secțiunea `location ~* \.(jpg|jpeg|...)`
- Verifică cache headers cu: `curl -I http://localhost/theme/image.jpg`

### HTTPS nu funcționează în Moodle:
- Verifică `X-Forwarded-Proto` header în nginx config
- Verifică `$CFG->wwwroot` în config.php folosește `https://`

## Performance Tuning

### 1. **nginx Worker Processes**
Dacă ai CPU multi-core, editează `nginx.conf`:
```nginx
# La început de fișier
worker_processes auto;  # sau număr specific de cores
worker_connections 1024;
```

### 2. **PHP-FPM Max Children**
Pentru trafic mare, crește în Dockerfile:
```dockerfile
echo 'pm.max_children = 100'; \
```

### 3. **nginx Buffer Sizes**
Pentru site-uri mari, crește buffer-ele:
```nginx
fastcgi_buffers 32 32k;
fastcgi_buffer_size 64k;
```

## Monitoring

### nginx Stats:
```bash
# Requests/sec, connections
docker-compose exec nginx cat /var/log/nginx/moodle-access.log | tail -100
```

### PHP-FPM Pool Stats:
```bash
# Vezi procese active
docker-compose exec php-fpm ps aux | grep php-fpm
```

### Resource Usage:
```bash
# Memorie per container
docker stats --no-stream
```

## Revert la Apache (dacă e necesar)

Dacă vrei să revii la Apache:

1. Checkout commit anterior:
   ```bash
   git log --oneline  # găsește hash-ul commit-ului pre-nginx
   git checkout <hash> -- Dockerfile docker-compose.yml
   ```

2. Șterge nginx.conf:
   ```bash
   rm nginx.conf README-NGINX.md
   ```

3. Rebuild:
   ```bash
   docker-compose down -v
   docker-compose up -d --build
   ```

## Next Steps

✅ Setup complet - nginx + PHP-FPM + Redis  
✅ Optimizări automate incluse  
✅ Scalabil pentru 200+ useri simultani  

### Pentru mai multă performanță:
1. Activează **Redis sessions** (vezi [README-REDIS.md](README-REDIS.md))
2. Configurează **MUC cache** în Redis
3. Tune **MariaDB** buffer pool (vezi [DOCKER.md](DOCKER.md))

---

**Questions?** Check [DOCKER.md](DOCKER.md) pentru detalii generale despre deployment.
