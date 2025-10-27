# Migration Options Comparison

## Quick Decision Matrix

| Factor | Option A: demo→app | Option C: app→5.1 | 
|--------|-------------------|-------------------|
| **Final Structure** | Moodle in `public/` | Moodle at root |
| **Base Version** | 5.1+ from demo | 5.1+ from MOODLE_501_STABLE |
| **Docker Config** | demo's proven setup | Keep current or merge |
| **Deployment** | Coolify-ready | Need adaptation |
| **Complexity** | ⭐⭐ Medium | ⭐⭐⭐ Medium-High |
| **Risk** | 🟢 Low | 🟡 Medium |
| **Best for** | Production deployment | Development/testing |

## My Recommendation: **Option A**

### Why Option A (Start from demo)?

✅ **Advantages:**
1. **Proven setup:** demo branch has working nginx + PHP-FPM configuration
2. **Modern structure:** `public/` subdirectory is better for security and deployment
3. **Coolify compatible:** Already configured for deployment platforms
4. **Clean 5.1:** No legacy code from migration
5. **Recent improvements:** HTTPS detection, phpMyAdmin, optimized Docker

❌ **Minor disadvantages:**
1. Need to move custom modules into `public/` structure (easy)
2. Slightly different file paths in deployment

### When to Choose Option C?

Choose if:
- You want to keep current deployment structure exactly as-is
- You have hardcoded paths pointing to root-level Moodle
- You don't want to adopt demo's Docker improvements

## Structure Comparison

### app branch (current):
```
/
├── admin/
├── mod/
│   ├── survey/      ← custom
│   ├── chat/        ← custom
│   └── quiz/
│       └── accessrule/
│           └── hidecorrect/  ← custom
├── theme/
│   └── almondb/     ← custom
├── payment/
│   └── gateway/
│       └── stripe/  ← custom
├── version.php      (5.0.2+)
├── Dockerfile
└── docker-compose.yml
```

### demo branch (target):
```
/
├── public/          ← Moodle root
│   ├── admin/
│   ├── mod/
│   ├── theme/
│   ├── payment/
│   └── version.php  (5.1+)
├── admin/           ← Admin tools at root
├── lib/             ← Shared libs at root
├── Dockerfile       ← Optimized
├── docker-compose.yml
├── docker-compose.dev.yml
├── nginx.conf
└── DEV_SETUP.md
```

### Target structure (Option A):
```
/
├── public/
│   ├── admin/
│   ├── mod/
│   │   ├── survey/      ← copied from app
│   │   ├── chat/        ← copied from app
│   │   └── quiz/
│   │       └── accessrule/
│   │           └── hidecorrect/  ← copied from app
│   ├── theme/
│   │   └── almondb/     ← copied from app
│   ├── payment/
│   │   └── gateway/
│   │       └── stripe/  ← copied from app
│   └── version.php      (5.1+)
├── !manual/             ← copied from app
├── Dockerfile           ← from demo
├── docker-compose.yml   ← from demo
└── nginx.conf           ← from demo
```

## Recommended Workflow (Option A)

```bash
# 1. Start from demo
git checkout demo
git checkout -b app-5.1-migration

# 2. Add custom modules to public/
git checkout app -- theme/almondb payment/gateway/stripe mod/survey mod/chat mod/quiz/accessrule/hidecorrect !manual

# 3. Move to public/ structure
mkdir -p public/theme public/payment/gateway public/mod/quiz/accessrule
mv theme/almondb public/theme/
mv payment/gateway/stripe public/payment/gateway/
mv mod/survey mod/chat public/mod/
mv mod/quiz/accessrule/hidecorrect public/mod/quiz/accessrule/

# 4. Clean up
rm -rf theme payment mod

# 5. Commit
git add -A
git commit -m "Add custom modules from app branch to demo 5.1 structure"

# 6. Test
docker-compose up --build
# Visit http://localhost/admin to run upgrade

# 7. Once verified, update app branch
git checkout app
git reset --hard app-5.1-migration
```

## Important Notes

### Config Changes Needed

After migration, update your `config.php`:
```php
// In demo structure, $CFG->dirroot points to public/
$CFG->dirroot  = '/var/www/html/public';  // Note: public subdirectory
$CFG->wwwroot  = 'https://yourdomain.com';
$CFG->dataroot = '/var/www/moodledata';
```

### Nginx Configuration

demo branch includes optimized `nginx.conf` that:
- Serves from `public/` directory
- Handles PHP-FPM properly
- Includes security headers
- Supports HTTPS detection via X-Forwarded-Proto

### Database Upgrade

After code migration:
```bash
# Run the upgrade script
docker exec -it moodle_container php /var/www/html/public/admin/cli/upgrade.php --non-interactive

# Or visit web interface
https://yourdomain.com/admin
```

### Custom Module Compatibility

All your custom modules should work without changes:
- `mod/survey`, `mod/chat` - Standard module structure
- `theme/almondb` - Theme structure unchanged
- `payment/gateway/stripe` - Gateway structure unchanged
- `mod/quiz/accessrule/hidecorrect` - Plugin structure unchanged

The only change is the parent directory (`public/` instead of root).
