#!/bin/bash
cd strategy-a
echo "Validando Strategy A..."
cloud-init schema --config-file user-data.yml && echo "OK: user-data.yml valido" || echo "ERROR: user-data.yml invalido"
echo "Archivos requeridos:"
[ -f user-data.yml ] && echo "OK: user-data.yml existe" || echo "ERROR: user-data.yml falta"
echo "Contenido verificado:"
grep -q "hostname:" user-data.yml && echo "OK: hostname configurado" || echo "ERROR: hostname falta"
grep -q "admin" user-data.yml && echo "OK: usuario admin configurado" || echo "ERROR: usuario falta"
grep -q "nginx" user-data.yml && echo "OK: nginx configurado" || echo "ERROR: nginx falta"
grep -q "ufw" user-data.yml && echo "OK: firewall configurado" || echo "ERROR: firewall falta"
grep -q "cleanup-logs.sh" user-data.yml && echo "OK: cron configurado" || echo "ERROR: cron falta"
echo "Strategy A: Validacion completa"

