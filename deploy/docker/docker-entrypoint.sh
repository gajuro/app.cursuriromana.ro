#!/bin/bash
set -e

CONFIG_PERSISTENT="/var/www/persistent/config.php"
CONFIG_APP="/var/www/html/config.php"

echo "=== Moodle Docker Entrypoint ==="

# Create persistent directory if needed
mkdir -p /var/www/persistent

# Restore config.php from persistent storage if it exists
if [ -f "$CONFIG_PERSISTENT" ]; then
    echo "✓ Found existing config.php in persistent storage, restoring..."
    cp "$CONFIG_PERSISTENT" "$CONFIG_APP"
    chown www-data:www-data "$CONFIG_APP"
    chmod 644 "$CONFIG_APP"
else
    echo "ℹ No config.php found - first run, Moodle installer will create it"
fi

# Function to save config.php to persistent storage
save_config() {
    if [ -f "$CONFIG_APP" ]; then
        # Only copy if changed to avoid unnecessary writes
        if ! cmp -s "$CONFIG_APP" "$CONFIG_PERSISTENT" 2>/dev/null; then
            echo "✓ Saving config.php to persistent storage..."
            cp "$CONFIG_APP" "$CONFIG_PERSISTENT"
            echo "✓ Config saved successfully at $(date)"
        fi
    fi
}

# Background job to periodically save config (every 30 seconds)
# This ensures config is saved even if container is killed ungracefully
(
    while true; do
        sleep 30
        save_config
    done
) &

# Save immediately on graceful shutdown signals
trap 'save_config; exit 0' SIGTERM SIGINT

# Set correct permissions (only on writable directories, not on mounted source code)
chown -R www-data:www-data /var/www/moodledata /var/www/localcache /var/www/persistent
chmod -R 755 /var/www/moodledata /var/www/localcache /var/www/persistent

echo "=== Starting nginx and PHP-FPM ==="

# Execute the main command (supervisord managing both nginx and PHP-FPM)
exec "$@"
