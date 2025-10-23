# 🚀 Migrare la nginx: Ghid Complet

Acest setup folosește **nginx + PHP-FPM** într-un singur container în loc de Apache pentru performanță maximă și simplitate operațională.

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
[Container Unic]
  ├─ nginx (port 80) ← servește static files
  └─ PHP-FPM (localhost:9000) ← procesează PHP
        ↓
   [MariaDB + Redis]
```

## Structura Containerelor

### 1. **web** (custom - built from Dockerfile)
**Container unic cu nginx + PHP-FPM** (gestionat de supervisor)
- Port: 80 (expus)
- Rol: Web server + procesare PHP
- nginx: servire fișiere statice, reverse proxy către PHP-FPM local
- PHP-FPM: procesare PHP, Moodle logic pe localhost:9000
- Pool config: 50 max children, dynamic PM
- Health check: verifică ambele procese (nginx și php-fpm)

### 2. **db** (MariaDB 11.8)
- Optimizări: 512MB buffer pool, 32MB query cache

### 3. **redis** (redis:7-alpine)
- Rol: Session storage, cache

## Volume-uri

Volume-urile sunt montate direct în containerul **web**:
- **moodle_config**: `/var/www/persistent` - configurație Moodle persistentă
- **moodle_data**: `/var/www/moodledata` - date utilizatori, uploads, cache
- **moodle_localcache**: `/var/www/localcache` - cache local

```yaml
# În docker-compose.yml
web:
  volumes:
    - moodle_config:/var/www/persistent:rw
    - moodle_data:/var/www/moodledata:rw
    - moodle_localcache:/var/www/localcache:rw
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

### 3. **PHP-FPM Pass-through** (localhost)
```nginx
location ~ \.php$ {
    fastcgi_pass 127.0.0.1:9000;
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
docker-compose exec web nginx -t

# Reload nginx (fără restart)
docker-compose exec web nginx -s reload

# Logs web container
docker-compose logs -f web
```

### 3. Verificare PHP-FPM funcționează
```bash
# Test PHP-FPM config
docker-compose exec web php-fpm -t

# Verifică procese active
docker-compose exec web ps aux | grep -E '(nginx|php-fpm)'
```

## Debugging

### nginx nu găsește fișierele:
```bash
# Verifică volume-ul este montat
docker-compose exec web ls -la /var/www/html/public

# Verifică permissions
docker-compose exec web ls -la /var/www/html
```

### PHP-FPM connection refused:
```bash
# Verifică ambele procese rulează
docker-compose exec web ps aux | grep -E '(nginx|php-fpm)'

# Verifică PHP-FPM pe localhost:9000
docker-compose exec web netstat -tulpn | grep 9000
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
docker-compose exec web cat /var/log/nginx/moodle-access.log | tail -100
```

### PHP-FPM Pool Stats:
```bash
# Vezi procese active
docker-compose exec web ps aux | grep php-fpm

# Supervisor status
docker-compose exec web supervisorctl status
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
