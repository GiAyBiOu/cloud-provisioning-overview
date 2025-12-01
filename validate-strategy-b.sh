#!/bin/bash
cd strategy-b
echo "Validando Strategy B..."
cloud-init schema --config-file user-data.yml && echo "OK: user-data.yml valido" || echo "ERROR: user-data.yml invalido"
echo "Archivos requeridos:"
[ -f user-data.yml ] && echo "OK: user-data.yml existe" || echo "ERROR: user-data.yml falta"
cd ansible
[ -f site.yml ] && echo "OK: site.yml existe" || echo "ERROR: site.yml falta"
if command -v ansible-playbook >/dev/null 2>&1; then
  ansible-playbook --syntax-check site.yml >/dev/null 2>&1 && echo "OK: playbook sintaxis valida" || echo "ERROR: playbook sintaxis invalida"
else
  echo "SKIP: ansible-playbook no instalado"
fi
echo "Contenido verificado:"
grep -q "hostname:" ../user-data.yml && echo "OK: hostname configurado" || echo "ERROR: hostname falta"
grep -q "admin" ../user-data.yml && echo "OK: usuario admin configurado" || echo "ERROR: usuario falta"
grep -q "ansible" ../user-data.yml && echo "OK: ansible instalado" || echo "ERROR: ansible falta"
grep -q "nginx" site.yml && echo "OK: nginx en playbook" || echo "ERROR: nginx falta"
grep -q "ufw" site.yml && echo "OK: firewall en playbook" || echo "ERROR: firewall falta"
grep -q "fail2ban" site.yml && echo "OK: hardening en playbook" || echo "ERROR: hardening falta"
echo "Strategy B: Validacion completa"

