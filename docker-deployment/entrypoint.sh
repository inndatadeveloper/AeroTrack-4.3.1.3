#!/bin/bash
#
# Copyright © 2016-2026 The Thingsboard Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Verified against the actual built jar via:
#   unzip -l application/target/thingsboard-4.3.1.3-boot.jar | grep -i "InstallApplication\|ServerApplication"
# This build's Java package was not rebranded (still org.thingsboard) --
# cosmetic only, doesn't affect functionality.
INSTALL_MAIN_CLASS="org.thingsboard.server.ThingsboardInstallApplication"

echo "=== AeroTrack Startup ==="
echo "Waiting for PostgreSQL..."
until nc -z "${DB_HOST:-postgres}" "${DB_PORT:-5432}"; do
  sleep 2
done
echo "PostgreSQL ready"

SCHEMA_MARKER="/aerotrack/data/.schema_installed"

if [ ! -f "$SCHEMA_MARKER" ]; then
  echo "Schema not found. Installing..."
  java -Dloader.path=/aerotrack \
       -Dloader.main="$INSTALL_MAIN_CLASS" \
       -Dspring.config.name=aerotrack \
       -Dlogging.config=/aerotrack/logback.xml \
       -Dinstall.data_dir=/aerotrack/data \
       -Dinstall.load_demo=false \
       -jar /aerotrack/aerotrack.jar \
       org.springframework.boot.loader.launch.PropertiesLauncher

  INSTALL_EXIT_CODE=$?
  if [ "$INSTALL_EXIT_CODE" -ne 0 ]; then
    echo "Installation FAILED with exit code $INSTALL_EXIT_CODE. Not starting server."
    exit "$INSTALL_EXIT_CODE"
  fi

  touch "$SCHEMA_MARKER"
  echo "Schema installation complete."
else
  echo "Schema already installed. Skipping installation."
fi

echo "Starting AeroTrack application..."
exec java -Dspring.config.name=aerotrack \
          -Dlogging.config=/aerotrack/logback.xml \
          -Dinstall.data_dir=/aerotrack/data \
          -jar /aerotrack/aerotrack.jar
