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

# AeroTrack Docker image
# Build context must be the AeroTrack repo ROOT (not this docker-deployment folder),
# e.g.: docker build -f docker-deployment/Dockerfile -t aerotrack:latest .

FROM eclipse-temurin:17-jre

RUN apt-get update && \
    apt-get install -y wget postgresql-client netcat-openbsd sed && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /aerotrack

# NOTE: adjust the jar filename below if your build produced a different
# version number than 4.3.1.3 (check application/target/*.jar to confirm).
COPY application/target/thingsboard-4.3.1.3-boot.jar /aerotrack/aerotrack.jar
COPY application/target/conf /aerotrack/conf
COPY application/target/data /aerotrack/data
COPY docker-deployment/logback.xml /aerotrack/logback.xml
COPY docker-deployment/entrypoint.sh /aerotrack/entrypoint.sh

RUN mkdir -p /aerotrack/logs && chmod +x /aerotrack/entrypoint.sh

ENTRYPOINT ["/aerotrack/entrypoint.sh"]
