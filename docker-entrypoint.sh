#!/bin/bash
set -e

CONFIG_PERSISTENT="/var/www/persistent/config.php"
CONFIG_APP="/var/www/html/public/config.php"

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
        echo "✓ Saving config.php to persistent storage..."
        cp "$CONFIG_APP" "$CONFIG_PERSISTENT"
        echo "✓ Config saved successfully"
    fi
}

# Save config on container stop
trap save_config EXIT SIGTERM SIGINT

# Set correct permissions
chown -R www-data:www-data /var/www/moodledata /var/www/localcache /var/www/persistent
chmod -R 755 /var/www/html

echo "=== Starting Apache ==="

# Execute the main command (Apache)
exec "$@"
