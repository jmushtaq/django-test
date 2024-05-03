#!/bin/bash

# Start the first process
env > /etc/.cronenv
sed -i 's/\"/\\"/g' /etc/.cronenv
cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1 > /app/git_hash

echo "Starting Gunicorn"
# Start the second process
gunicorn mysite.wsgi --bind :8080 --config /app/gunicorn.ini
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start gunicorn: $status"
  exit $status
fi

