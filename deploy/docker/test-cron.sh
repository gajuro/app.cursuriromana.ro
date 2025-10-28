#!/bin/bash

echo "=== Moodle Cron Test Script ==="
echo "This script tests if the Moodle cron setup is working correctly."
echo ""

# Check if container is running
if ! docker-compose ps web | grep -q "Up"; then
    echo "❌ Web container is not running. Please start with: docker-compose up -d"
    exit 1
fi

echo "✓ Web container is running"

# Check if cron service is running in supervisor
echo "Checking cron service status..."
docker-compose exec web supervisorctl status cron

# Check if crontab is configured
echo ""
echo "Checking crontab configuration..."
docker-compose exec web crontab -u www-data -l

# Test manual cron execution
echo ""
echo "Testing manual cron execution..."
echo "Running: php admin/cli/cron.php --help"
docker-compose exec web php admin/cli/cron.php --help

# Check if cron processes are running
echo ""
echo "Checking for running cron processes..."
docker-compose exec web ps aux | grep cron

echo ""
echo "=== Cron Test Complete ==="
echo ""
echo "To monitor cron execution in real-time:"
echo "  docker-compose exec web tail -f /var/log/cron/cron.log"
echo ""
echo "To run cron manually for testing:"
echo "  docker-compose exec web php admin/cli/cron.php"
echo ""
echo "To check Moodle's scheduled tasks:"
echo "  Visit: http://localhost/admin/tool/task/scheduledtasks.php"
