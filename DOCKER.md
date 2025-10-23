# Moodle Docker Deployment pentru Coolify

## Structura Setup-ului

Setup-ul Docker este optimizat pentru deployments pe Coolify și include:

### 1. **Dockerfile Multi-Stage**
- **Stage 1 (os)**: Configurare sistem de bază (PHP 8.2, Apache, extensii)
- **Stage 2 (moodle)**: Aplicația Moodle cu configurări specifice
- **Database**: MariaDB 11.8 LTS (latest long-term support)
- **Redis**: Redis 7 Alpine pentru sessions și cache (opțional, dar recomandat)

### 2. **Volume-uri Persistente**

Următoarele sunt configurate pentru persistență:

#### Fișiere/Directoare Critice:
- **config.php**: Bind mount direct la fișier (generat la instalare)
- **moodledata/**: Named volume pentru toate fișierele (uploads, cache, sesiuni)
- **localcache/**: Named volume pentru cache local (performanță îmbunătățită)

#### Volume-uri Opționale (decomentați în docker-compose.yml dacă e necesar):
- **local/**: Plugin-uri custom
- **theme/**: Teme custom

### 3. **Fișiere Generate la Runtime**

Pe lângă `config.php`, Moodle poate genera/modifica:
- Fișiere în `moodledata/`:
  - `filedir/` - fișiere uploadate
  - `sessions/` - sesiuni utilizatori
  - `cache/` - cache-uri
  - `temp/` - fișiere temporare
  - `trashdir/` - fișiere șterse
  - `lang/` - pachete de limbă
- `localcache/` - cache local pentru performanță

Toate acestea sunt acoperite de volume-ul `moodle_data`.

## Instalare Rapidă

### 1. Pregătire

```bash
# Copiază și editează fișierul de configurare
cp .env.example .env
nano .env
```

Editează `.env` cu valorile tale:
- `WWWROOT` - URL-ul public al site-ului
- `DB_PASSWORD` - parolă securizată pentru baza de date
- `DB_ROOT_PASSWORD` - parolă root pentru MariaDB
- `ADMIN_PASSWORD` - parolă pentru admin Moodle
- `ADMIN_EMAIL` - email admin

### 2. Build și Pornire

```bash
# Build image
docker-compose build

# Pornește serviciile
docker-compose up -d

# Verifică logs
docker-compose logs -f moodle
```

### 3. Instalare Moodle

După pornirea containerelor, accesează `http://localhost` (sau URL-ul configurat) și urmează wizard-ul de instalare:

1. Selectează limba
2. Verifică path-urile (ar trebui să fie deja configurate)
3. Alege tipul bazei de date (MariaDB)
4. Introdu credențialele bazei de date (din `.env`)
5. Acceptă termenii și licența
6. Verifică cerințele sistemului
7. Instalează baza de date
8. Creează contul admin

După instalare, `config.php` va fi generat automat și persistat în volume.

## Deploy în Coolify

### Opțiunea 1: Git Repository

1. Push codul pe Git (GitHub, GitLab, etc.)
2. În Coolify:
   - New Resource → Application
   - Selectează repository-ul
   - Build Pack: Dockerfile
   - Setează variabilele de mediu din `.env`
   - Deploy

### Opțiunea 2: Docker Compose

1. În Coolify:
   - New Resource → Docker Compose
   - Paste conținutul din `docker-compose.yml`
   - Configurează variabilele de mediu
   - Deploy

### Variabile de Mediu în Coolify

Setează următoarele variabile în Coolify:

```
WWWROOT=https://your-domain.com
DB_PASSWORD=your_secure_password
DB_ROOT_PASSWORD=your_root_password
ADMIN_PASSWORD=your_admin_password
ADMIN_EMAIL=your@email.com
```

## Comenzi Utile

```bash
# Oprește serviciile
docker-compose down

# Oprește și șterge volume-urile (ATENȚIE: șterge toate datele!)
docker-compose down -v

# Restart servicii
docker-compose restart

# Verifică servicii
docker-compose ps

# Accesează bash în container
docker-compose exec moodle bash

# Backup volume config
docker run --rm -v app.cursuriromana.ro_moodle_config:/data -v $(pwd):/backup alpine tar czf /backup/config-backup.tar.gz -C /data .

# Backup volume moodledata
docker run --rm -v app.cursuriromana.ro_moodle_data:/data -v $(pwd):/backup alpine tar czf /backup/moodledata-backup.tar.gz -C /data .

# Backup database
docker-compose exec db mysqldump -u root -p${DB_ROOT_PASSWORD} ${DB_NAME} > moodle-db-backup.sql
```

## Upgrade Moodle

1. **Backup:**
   ```bash
   docker-compose exec db mysqldump -u root -p moodle > backup.sql
   docker run --rm -v app.cursuriromana.ro_moodle_data:/data -v $(pwd):/backup alpine tar czf /backup/moodledata.tar.gz -C /data .
   ```

2. **Update cod:**
   ```bash
   git pull origin main
   ```

3. **Rebuild:**
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

4. **Accesează** `/admin` pentru a finaliza upgrade-ul

## Troubleshooting

### Container nu pornește
```bash
docker-compose logs moodle
```

### Erori de permisiuni
```bash
docker-compose exec moodle chown -R www-data:www-data /var/www/html /var/www/moodledata
```

### Reset complet (ATENȚIE: șterge toate datele!)
```bash
docker-compose down -v
docker-compose up -d
```

## Performance Tips

### 1. Redis pentru Sessions și Cache ⚡

Redis este **deja configurat** în `docker-compose.yml` și oferă îmbunătățiri semnificative de performanță:
- **30-50% reducere** load bază de date
- **20-40% mai rapid** la pagini cu autentificare
- Suport pentru multe sesiuni simultane

#### Activare Redis Sessions:

1. **După instalarea Moodle**, editează `config.php`:
   ```bash
   docker-compose exec moodle nano /var/www/html/config.php
   ```

2. **Adaugă configurația Redis** după secțiunea database setup:
   ```php
   // Redis session handler
   $CFG->session_handler_class = '\core\session\redis';
   $CFG->session_redis_host = 'redis';
   $CFG->session_redis_port = 6379;
   $CFG->session_redis_database = 0;
   $CFG->session_redis_prefix = 'mdl_sess_';
   $CFG->session_redis_acquire_lock_timeout = 120;
   $CFG->session_redis_lock_expire = 7200;
   ```

3. **Salvează și restart:**
   ```bash
   docker-compose restart moodle
   ```

#### Verificare Redis funcționează:
```bash
# Verifică că Redis rulează
docker-compose exec redis redis-cli ping
# Răspuns așteptat: PONG

# Verifică sesiunile în Redis
docker-compose exec redis redis-cli KEYS "mdl_sess_*"
```

#### Note:
- Redis folosește max **256MB RAM** (configurat cu `maxmemory-policy allkeys-lru`)
- Nu necesită persistență (sesiunile sunt temporare)
- Se pornește automat odată cu Moodle

### 2. Creșteți memory_limit pentru site-uri mari:
   ```env
   PHP_MEMORY_LIMIT=512M
   ```

### 3. Monitorizați logs:
   ```bash
   docker-compose logs -f --tail=100 moodle
   ```

## Securitate

- Schimbă toate parolele default din `.env`
- Folosește HTTPS în producție (configurează în Coolify)
- Actualizează regulat Moodle la ultima versiune
- Setează backup-uri automate
- Nu expune portul bazei de date public (elimină `ports` pentru serviciul `db` în producție)

## Suport

Pentru probleme specifice Moodle: https://docs.moodle.org/
Pentru probleme Docker: https://docs.docker.com/
