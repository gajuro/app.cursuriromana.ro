# 🚀 Ghid Rapid: Activare Redis pentru Moodle

Redis este **deja inclus** în setup-ul Docker și aduce îmbunătățiri semnificative de performanță pentru Moodle.

## Beneficii Redis

✅ **30-50% reducere** load pe baza de date  
✅ **20-40% viteză mărită** la pagini cu autentificare  
✅ **Suport excelent** pentru mulți utilizatori simultani  
✅ **Foarte light**: folosește doar ~30-50MB RAM  

## Activare în 3 pași

### 1️⃣ Pornește containerele (Redis e deja inclus)

```bash
docker-compose up -d
```

### 2️⃣ După instalarea Moodle, editează `config.php`

**Opțiunea A - Din container:**
```bash
docker-compose exec moodle nano /var/www/html/config.php
```

**Opțiunea B - În Coolify:**
- Mergi la File Manager
- Deschide `/var/www/html/config.php`

### 3️⃣ Adaugă configurația Redis

Caută secțiunea `// 1b. REDIS SESSION HANDLER` și **decomentează** liniile (șterge `//` de la început):

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

Sau adaugă codul mai sus după secțiunea database (`$CFG->dboptions`), dar **înainte de** `$CFG->wwwroot`.

### 4️⃣ Restart Moodle

```bash
docker-compose restart moodle
```

## ✓ Verificare că funcționează

```bash
# Verifică Redis rulează
docker-compose exec redis redis-cli ping
# Răspuns așteptat: PONG

# Verifică sesiunile în Redis (după ce te loghezi în Moodle)
docker-compose exec redis redis-cli KEYS "mdl_sess_*"
# Ar trebui să vezi chei de sesiuni
```

## Troubleshooting

### Redis nu pornește
```bash
docker-compose logs redis
docker-compose restart redis
```

### Sesiunile nu apar în Redis
1. Verifică că ai **decomenttat** liniile în `config.php` (fără `//`)
2. Verifică că ai **restartat** Moodle după modificare
3. **Loghează-te** în Moodle și apoi verifică din nou cu `KEYS "mdl_sess_*"`

### Eroare "Class '\core\session\redis' not found"
Verifică că extensia phpredis este instalată:
```bash
docker-compose exec moodle php -m | grep redis
# Ar trebui să vezi "redis"
```

Dacă nu există, rebuild imaginea:
```bash
docker-compose build --no-cache moodle
docker-compose up -d
```

## Configurație Redis

Redis este configurat automat cu:
- **256MB maxmemory** (suficient pentru ~10.000 sesiuni simultane)
- **allkeys-lru policy** (șterge automat sesiunile cele mai vechi când se umple)
- **No persistence** (sesiunile sunt efemere, nu e nevoie de salvare pe disk)

## Monitorizare Redis

```bash
# Statistici Redis
docker-compose exec redis redis-cli INFO stats

# Memorie folosită
docker-compose exec redis redis-cli INFO memory

# Număr de chei (sesiuni)
docker-compose exec redis redis-cli DBSIZE
```

## Next Steps: MUC Cache (opțional)

Pentru și mai multă performanță, poți configura și **Moodle Universal Cache (MUC)** în Redis:
- Mergi în Moodle: `Site administration` → `Plugins` → `Caching` → `Configuration`
- Adaugă un Redis store
- Mapează cache-urile dorite la Redis

**Notă**: Sessions în Redis aduce cel mai mare beneficiu. MUC în Redis e un bonus nice-to-have.

---

**Questions?** Check [DOCKER.md](DOCKER.md) pentru mai multe detalii.
