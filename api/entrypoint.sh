#!/bin/bash
set -e
F=/app/conf/META-INF/persistence.xml

# Point Hibernate at the compose postgres service and keep data between restarts
sed -i -E \
  -e "s#jdbc:postgresql://[^\"]*#jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}#" \
  -e "/jdbc.user/ s#value=\"[^\"]*\"#value=\"${DB_USER}\"#" \
  -e "/jdbc.password/ s#value=\"[^\"]*\"#value=\"${DB_PASSWORD}\"#" \
  -e "/hbm2ddl.auto/ s#value=\"[^\"]*\"#value=\"update\"#" \
  "$F"
grep -E "jdbc|hbm2ddl" "$F" || true

# Allow requests addressed to the compose service name (Play AllowedHostsFilter)
printf '\nplay.filters.hosts.allowed = ["localhost", "127.0.0.1", "api", "api:9000", "localhost:9000", "127.0.0.1:9000"]\n' >> /app/conf/application.conf

cd /app
# Play dev mode stops on stdin EOF; keep stdin open forever
tail -f /dev/null | sbt run
