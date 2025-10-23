# Docker Setup - Quick Start

## 🚀 Pornire Rapidă

```bash
# 1. Copiază și configurează environment
cp .env.example .env
nano .env  # editează cu valorile tale

# 2. Build și pornește
docker-compose up -d

# 3. Verifică logs
docker-compose logs -f web

# 4. Accesează: http://localhost (sau URL-ul configurat)
```

## 📦 Ce Include

- **Dockerfile multi-stage**: `os` (sistem de bază) + `moodle` (aplicație)
- **Container unic**: nginx + PHP-FPM gestionat de supervisor
- **Volume persistente**:
  - **Named volume** - `moodle_config` (config.php persistent)
  - **Named volume** - `moodle_data` (uploads, cache, sessions)
  - **Named volume** - `moodle_localcache` (cache local pentru performanță)
  - **Named volume** - `db_data` (baza de date MariaDB 11.8 LTS)
- **Entrypoint script** - setează permisiuni și gestionează config.php
- **Health checks** - verifică nginx și PHP-FPM

## 🔧 Deployment Coolify

### Variabile de mediu obligatorii:
```
WWWROOT=https://your-domain.com
DB_PASSWORD=your_secure_password
DB_ROOT_PASSWORD=your_root_password
ADMIN_PASSWORD=your_admin_password
ADMIN_EMAIL=your@email.com
```

### În Coolify:
1. New Resource → Docker Compose
2. Paste `docker-compose.yml`
3. Setează variabilele de mediu
4. Deploy

## 📝 Note Importante

1. **config.php** este gestionat automat:
   - La prima instalare: Moodle îl creează prin wizard
   - La pornire: Entrypoint îl restaurează din volume persistent
   - La oprire: Entrypoint îl salvează automat în volume
   - Nu necesită intervenție manuală!
2. **moodledata/** include: filedir, sessions, cache, temp, trashdir, lang
3. **localcache/** este opțional dar recomandat pentru performanță
4. Toate volume-urile sunt persistente între redeploy-uri

## 🛠️ Comenzi Utile

```bash
# Restart
docker-compose restart

# Stop
docker-compose down

# Logs
docker-compose logs -f web

# Bash în container
docker-compose exec web bash

# Backup DB
docker-compose exec db mysqldump -u root -p${DB_ROOT_PASSWORD} ${DB_NAME} > backup.sql
```

Pentru detalii complete vezi **[DOCKER.md](./DOCKER.md)**
