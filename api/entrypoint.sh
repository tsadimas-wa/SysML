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

# Play's AllowedHostsFilter: which Host headers the API accepts.
# ALLOWED_HOSTS is comma separated; "." (or "*") means any host (default).
# e.g. ALLOWED_HOSTS=localhost,api,10.100.52.117
HOSTS_CONF=$(printf '%s' "${ALLOWED_HOSTS:-.}" | awk -v RS=, 'NF{gsub(/^[ \t]+|[ \t]+$/,""); if ($0=="*") $0="."; printf "%s\"%s\"", (n++?", ":""), $0}')
printf '\nplay.filters.hosts.allowed = [%s]\n' "$HOSTS_CONF" >> /app/conf/application.conf
tail -n 2 /app/conf/application.conf

cd /app
# Play dev mode stops on stdin EOF; keep stdin open forever
tail -f /dev/null | sbt run
