# Upgrade Plan: app (5.0.2+) → demo (5.1+ with public/ structure)

## Current Situation
- **Current branch:** `app` (Moodle 5.0.2+ at root level)
- **Target branch:** `demo` (Moodle 5.1+ in `public/` subdirectory)
- **Common ancestor:** commit 78e86017831 (Moodle release 5.0)
- **Key differences:**
  - `demo` has Moodle in `public/` subdirectory
  - `demo` uses Moodle 5.1+ (Build: 20251024)
  - `app` has custom modules that `demo` doesn't have
  - Different Docker configurations
- **Backup created:** `app-backup-5.0.2` branch

## Custom Components in app Branch (to preserve)
1. **Theme:** `theme/almondb/` ❌ NOT in demo
2. **Payment Gateway:** `payment/gateway/stripe/` ❌ NOT in demo
3. **Custom Modules:** ❌ NOT in demo
   - `mod/survey/` (custom module)
   - `mod/chat/` (restored after core removal in 5.1)
   - `mod/quiz/accessrule/hidecorrect/` (custom access rule)
4. **Docker Configuration:** Different between branches
5. **Manual Customizations:** `!manual/` directory ❌ NOT in demo

## demo Branch Structure
- **Moodle location:** `public/` subdirectory (360MB)
- **Moodle version:** 5.1+ (Build: 20251024), branch 501
- **Docker setup:** nginx + PHP-FPM in single container
- **Recent changes:** phpMyAdmin, HTTPS detection fixes, Coolify compatibility
- **Missing:** All custom modules from app branch

## Recommended Approach: Merge demo + Restore Custom Modules

### Option A: Start from demo, Add Custom Modules (RECOMMENDED)

**Pros:** 
- Clean 5.1+ codebase from demo
- Proven Docker setup from demo
- public/ subdirectory structure (better for deployment)
- Minimal conflicts

**Cons:** 
- Need to add custom modules to public/ structure
- Evaluate which Docker config to keep

#### Steps:

1. **Create migration branch from demo:**
   ```bash
   git checkout demo
   git checkout -b app-5.1-migration
   ```

2. **Copy custom modules into public/ subdirectory:**
   ```bash
   # Custom theme (into public/theme/)
   git checkout app -- theme/almondb
   mkdir -p public/theme/
   mv theme/almondb public/theme/
   
   # Custom payment gateway (into public/payment/gateway/)
   git checkout app -- payment/gateway/stripe
   mkdir -p public/payment/gateway/
   mv payment/gateway/stripe public/payment/gateway/
   
   # Custom modules
   git checkout app -- mod/survey
   mkdir -p public/mod/
   mv mod/survey public/mod/
   
   git checkout app -- mod/chat
   mv mod/chat public/mod/
   
   git checkout app -- mod/quiz/accessrule/hidecorrect
   mkdir -p public/mod/quiz/accessrule/
   mv mod/quiz/accessrule/hidecorrect public/mod/quiz/accessrule/
   
   # Manual customizations
   git checkout app -- \!manual
   ```

3. **Review Docker configuration differences:**
   ```bash
   # Compare Docker setups
   git diff app demo -- Dockerfile docker-compose.yml
   
   # Decide which to keep or merge manually
   # demo has: nginx + PHP-FPM in single container, phpMyAdmin
   # app has: your custom Docker setup
   ```

4. **Update version and check structure:**
   ```bash
   # Verify Moodle version
   cat public/version.php
   
   # Check custom modules are in place
   ls -la public/theme/almondb
   ls -la public/mod/survey
   ls -la public/mod/chat
   ls -la public/payment/gateway/stripe
   ```

5. **Stage and commit:**
   ```bash
   git add -A
   git commit -m "Migrate app custom modules to demo 5.1+ structure"
   ```

6. **Test thoroughly:**
   - Build Docker container
   - Run Moodle upgrade: `php public/admin/cli/upgrade.php`
   - Verify all custom modules work
   - Test theme rendering

### Option B: Merge demo into app, Then Restructure (Complex)

⚠️ **Warning:** This is complex due to structural differences (root vs public/ subdirectory)

1. **Try merging demo into app:**
   ```bash
   git checkout app
   git merge --no-commit demo
   # Expect MANY conflicts due to structure difference
   ```

2. **Resolve structural conflicts:**
   - demo has Moodle in both root AND public/
   - app has Moodle at root only
   - You'll need to decide on final structure

3. **This approach is NOT recommended** due to complexity

### Option C: Manual Merge - Keep app Structure, Upgrade Core (Alternative)

If you prefer keeping Moodle at root (not in public/):

1. **Start from app, upgrade core files:**
   ```bash
   git checkout app
   git checkout -b app-core-upgrade
   
   # Get MOODLE_501_STABLE core files, excluding your custom modules
   git checkout MOODLE_501_STABLE -- . 
   
   # Restore custom modules
   git checkout app-backup-5.0.2 -- theme/almondb
   git checkout app-backup-5.0.2 -- payment/gateway/stripe
   git checkout app-backup-5.0.2 -- mod/survey
   git checkout app-backup-5.0.2 -- mod/chat
   git checkout app-backup-5.0.2 -- mod/quiz/accessrule/hidecorrect
   git checkout app-backup-5.0.2 -- \!manual
   ```

2. **Review Docker configs:**
   ```bash
   # Compare and manually merge the better parts
   git show demo:Dockerfile > /tmp/demo-Dockerfile
   git show demo:docker-compose.yml > /tmp/demo-docker-compose.yml
   # Manually merge what you need
   ```

## Next Steps

1. **Choose your preferred option** (I recommend Option A)
2. **Test the upgraded installation:**
   - Database upgrade: `/admin/index.php`
   - Theme functionality
   - Custom modules
   - Payment gateway
3. **Once verified, update the app branch:**
   ```bash
   git checkout app
   git reset --hard app-5.1-migration  # or your new branch name
   git push origin app --force-with-lease
   ```

## Important Notes

- ⚠️ Always test in development first
- 📸 Take database backup before upgrading
- 🔍 Check Moodle 5.1 changelog for breaking changes
- 📝 Update version.php after upgrade
- 🧪 Run `php admin/cli/upgrade.php` after code update

## Rollback Plan

If anything goes wrong:
```bash
git checkout app-backup-5.0.2
git branch -D app-5.1-migration  # or problematic branch
```

Your original app branch is safely backed up!
