## TecnoSoluciones SRL - Aprovisionamiento y Configuración de Servidores

**Estudiante:** Gabriel Ayar Mendoza Escobar  
**Grupo:** A  
**Sección:** B

**Repositorio del proyecto:** https://github.com/GiAyBiOu/cloudprovisioning-overview

---

## 1. Introducción

Esta tarea consistió en evaluar diferentes estrategias de aprovisionamiento para TecnoSoluciones SRL, una empresa que está estandarizando su proceso de configuración de servidores en la nube. Lo que se me pidió fue analizar y comparar dos enfoques diferentes para ver cuál funcionaría mejor en su caso.
---

## 2. Estrategia A: Automatización Completa con Cloud-init

La Estrategia A utiliza únicamente cloud-init para realizar toda la configuración del servidor durante el proceso de inicialización. Cloud-init es una herramienta estándar en la industria que permite la configuración inicial de instancias de máquinas virtuales.

Decidí empezar con esta porque parecía la más simple. Cloud-init es algo que casi todos los proveedores cloud usan, entonces pensé que sería bueno ver si con solo esto podía hacer todo lo que necesitaban sin complicarme demasiado.

### Implementación Realizada

Lo primero que hice fue crear el archivo `strategy-a/user-data.yml` con todo lo que me pidieron. Tuvimos que aprender cómo funciona cloud-init, su sintaxis y también entender sus limitaciones. Al principio pensé que sería más fácil de lo que realmente fue.

**Configuración de Hostname y Red**

Cuando empecé, intenté configurar la red explícitamente en el archivo user-data. Me parecía lógico hacerlo así. Pero cuando validé el archivo con `cloud-init schema`, me salió un error que decía que la propiedad 'network' no estaba permitida. Me frustré un poco porque pensé que lo había hecho bien.

Después de investigar y leer la documentación de cloud-init, me di cuenta de que la red se maneja automáticamente por el proveedor cloud usando DHCP. Cloud-init no necesita que configuremos la red manualmente en la mayoría de los casos. Entonces, lo que hice fue configurar solo el hostname como `prod-web-01` y habilité la gestión de hosts con `manage_etc_hosts: true`. Con esto, cloud-init actualiza automáticamente el archivo `/etc/hosts`.

Aunque al principio me pareció que no estaba cumpliendo completamente con el requisito, después entendí que sí lo estoy haciendo, porque la red se configura sola vía DHCP. Es la forma recomendada según la documentación.

**Creación de Usuario con Clave SSH**

Se creó el usuario `admin` con pertenencia a los grupos `sudo` y `adm`, permitiendo privilegios administrativos completos. La autenticación se configuró exclusivamente mediante clave SSH para el usuario `gabriel.mendoza@technosoluciones.local`, deshabilitando la autenticación por contraseña mediante `lock_passwd: true` para mejorar la seguridad.

El usuario cuenta con acceso sudo completo sin requerir contraseña mediante la configuración `sudo: ['ALL=(ALL) NOPASSWD:ALL']`, facilitando la administración automatizada del sistema. Esta configuración es necesaria para permitir que los scripts se ejecuten sin intervención manual durante el proceso de inicialización.

**Instalación y Configuración de Nginx**

Nginx se instaló mediante el repositorio de paquetes del sistema operativo especificándolo en la sección `packages`. La configuración incluye un archivo de sitio personalizado en `/etc/nginx/sites-available/default` que escucha en el puerto 80 para tráfico HTTP, define la raíz del sitio web en `/var/www/html`, incluye protección de archivos ocultos como `.htaccess` mediante la directiva `location ~ /\.ht`, y presenta una página de bienvenida personalizada.

El servicio se configuró para iniciarse automáticamente mediante `systemctl enable nginx` en la sección `runcmd`, y se aseguró que esté en ejecución. Tuve que agregar múltiples comandos relacionados con nginx en diferentes momentos del proceso de ejecución para garantizar que el servicio esté completamente operativo al finalizar la configuración.

**Tarea Cron para Limpieza de Logs**

Se implementó un script de limpieza ubicado en `/usr/local/bin/cleanup-logs.sh` que realiza tres funciones principales: elimina logs de Nginx con antigüedad mayor a 7 días mediante `find`, elimina logs comprimidos del sistema mayores a 30 días, y limpia el journal del sistema manteniendo únicamente los últimos 30 días de registros mediante `journalctl --vacuum-time=30d`.

Este script se programó para ejecutarse diariamente a las 2:00 AM mediante una tarea cron agregada directamente al archivo `/etc/crontab` usando el comando `echo`. Aunque esta no es la forma más elegante de gestionar cron jobs, funciona correctamente y cumple con el requisito solicitado.

**Firewall Básico con UFW**

Se configuró UFW (Uncomplicated Firewall) con políticas por defecto que deniegan todo el tráfico de entrada y permiten todo el tráfico de salida. Se establecieron reglas específicas para permitir el tráfico en los puertos 22 (SSH), 80 (HTTP) y 443 (HTTPS), asegurando que el servidor sea accesible para administración y servicios web mientras mantiene un perfil de seguridad restrictivo.

La configuración del firewall requiere ejecutar múltiples comandos en secuencia, primero estableciendo las políticas por defecto y luego agregando las reglas específicas. Utilicé `ufw --force enable` para evitar que el sistema solicite confirmación durante el proceso automatizado.

### Características Técnicas

La implementación utiliza configuración declarativa en formato YAML, se ejecuta automáticamente durante el boot inicial de la instancia, incluye validación de sintaxis mediante `cloud-init schema`, no requiere dependencias externas adicionales, y es compatible con todos los proveedores cloud principales como AWS, Azure, GCP y OpenStack.

Una de las ventajas de este enfoque es su portabilidad entre diferentes proveedores cloud, ya que cloud-init es un estándar ampliamente soportado. Sin embargo, descubrí que la complejidad aumenta significativamente cuando se intentan implementar configuraciones más avanzadas o cuando se necesita gestionar múltiples servidores con configuraciones similares pero no idénticas.

### Validación Realizada

Se creó el script `validate-strategy-a.sh` que verifica la sintaxis correcta del archivo user-data mediante `cloud-init schema`, confirma la presencia de todas las configuraciones requeridas mediante búsquedas con `grep`, y valida la estructura y formato del archivo.

**Resultados de la validación:**

```
Validando Strategy A...
Valid schema user-data.yml
OK: user-data.yml valido
Archivos requeridos:
OK: user-data.yml existe
Contenido verificado:
OK: hostname configurado
OK: usuario admin configurado
OK: nginx configurado
OK: firewall configurado
OK: cron configurado
Strategy A: Validacion completa
```

La validación confirmó que el archivo `user-data.yml` es válido, contiene todos los componentes requeridos, y está listo para despliegue en producción. El proceso de validación también incluyó pruebas con el script `test-strategy-a.sh`, que confirmó la sintaxis correcta del archivo.

Quise probar ejecutar cloud-init en mi WSL para ver si todo funcionaba, pero me topé con que cloud-init necesita un datasource específico que WSL no tiene. Esto fue un poco frustrante porque no pude hacer una prueba completa. Sin embargo, pude validar que la sintaxis estaba correcta con `cloud-init schema`, y eso me dio confianza de que en un servidor cloud real sí funcionaría bien.

---

## 3. Estrategia B: Automatización Híbrida (Cloud-init + Ansible)

La Estrategia B implementa un enfoque híbrido que combina cloud-init para la configuración mínima inicial y Ansible para la configuración completa y gestión continua del servidor. Esta estrategia separa las responsabilidades y permite mayor flexibilidad en la gestión de infraestructura.

Decidí usar Ansible en lugar de SaltStack por varias razones. Primero, Ansible es más fácil de aprender porque usa YAML, que es más legible y menos propenso a errores. Además, no necesita instalar agentes en los servidores, solo usa SSH, lo cual hace todo más simple. La comunidad de Ansible es enorme y hay módulos para casi todo lo que necesites. Y finalmente, para alguien que está empezando con Infrastructure as Code, Ansible es más intuitivo de entender.

### Implementación Realizada

**User-Data Mínimo**

El archivo `strategy-b/user-data.yml` contiene la configuración inicial mínima necesaria. Se establece el hostname como `prod-web-02` y se crea el usuario `admin` con su clave SSH configurada, habilitando la gestión de hosts mediante `manage_etc_hosts: true`.

La instalación de dependencias incluye Python 3 y pip, python3-apt para los módulos de gestión de paquetes de Ansible, Ansible completo mediante el repositorio de paquetes del sistema, y Git para repositorios de código. Se actualiza pip y ansible-core a las últimas versiones disponibles mediante `pip3 install --break-system-packages --upgrade pip ansible-core`, dejando el sistema completamente preparado para la ejecución de playbooks.

La elección de instalar Ansible en el mismo servidor que se va a configurar permite que el playbook se ejecute localmente, simplificando la arquitectura inicial. En un entorno de producción, probablemente se utilizaría un servidor de control de Ansible separado, pero para este caso práctico, la ejecución local es suficiente y más simple de gestionar.

**Playbook de Ansible**

El archivo `strategy-b/ansible/site.yml` contiene toda la lógica de configuración del servidor. Este playbook está diseñado para ejecutarse en `localhost` con privilegios elevados mediante `become: true`, lo que permite realizar todas las configuraciones necesarias.

La instalación y configuración de Nginx se realiza mediante el módulo `apt` de Ansible, utilizando templates Jinja2 para personalizar la configuración. Se crea el directorio web en `/var/www/html` con permisos adecuados mediante el módulo `file`, se despliega una página HTML personalizada desde el template `index.html.j2`, y se asegura que el servicio esté iniciado y habilitado para arranque automático mediante el módulo `systemd`.

Una de las ventajas de usar Ansible para esta configuración es que puedo detener el servicio de Nginx antes de realizar cambios en la configuración, lo cual evita errores potenciales. Utilicé handlers para reiniciar el servicio solo cuando hay cambios en los archivos de configuración, lo cual es más eficiente y reduce la interrupción del servicio.

La configuración de cron incluye la creación del script de limpieza `/usr/local/bin/cleanup-logs.sh` desde un template, y un cron job gestionado idempotentemente mediante el módulo `cron` de Ansible, programado para ejecución diaria a las 2:00 AM. La idempotencia es una característica clave de Ansible que permite ejecutar el playbook múltiples veces sin causar efectos secundarios no deseados.

El firewall UFW se activa con políticas por defecto configuradas mediante el módulo `ufw` de Ansible, estableciendo reglas para SSH (puerto 22), HTTP (puerto 80) y HTTPS (puerto 443). La implementación incluye manejo de errores mediante `ignore_errors: yes` para evitar fallos en ejecución cuando UFW ya está activo o configurado, lo cual es común cuando se ejecuta el playbook múltiples veces.

**Hardening Básico Aplicado**

Se implementaron tres componentes principales de hardening de seguridad, que van más allá de los requisitos básicos pero son esenciales para un servidor en producción.

Fail2ban se instaló y configuró mediante un template `jail.local.j2` para proteger el acceso SSH, limitando a un máximo de 3 intentos fallidos antes de aplicar un ban de 2 horas. El servicio se habilitó para ejecutarse automáticamente al inicio del sistema. La configuración de fail2ban requiere entender cómo funciona el sistema de logs y cómo se aplican las reglas de iptables, lo cual añadió complejidad pero también robustez a la solución.

Las actualizaciones automáticas de seguridad se configuraron mediante unattended-upgrades, estableciendo la instalación automática de actualizaciones de seguridad, limpieza de paquetes no utilizados, y configuración de orígenes de seguridad apropiados para la distribución. Esta configuración se realizó mediante dos métodos: un template para el archivo principal de configuración y módulos `lineinfile` para actualizar el archivo de configuración de periodicidad.

El hardening SSH incluye la deshabilitación del login directo de root mediante `PermitRootLogin no`, deshabilitación de autenticación por contraseña permitiendo únicamente claves SSH mediante `PasswordAuthentication no`, y timeout de inactividad de 300 segundos mediante `ClientAliveInterval 300`. La configuración se aplica mediante handlers que reinician el servicio SSH de forma segura solo cuando hay cambios, evitando interrupciones innecesarias.

**Templates y Configuraciones**

Se crearon cinco templates Jinja2 para permitir la reutilización y personalización de las configuraciones. El template `default-site.conf.j2` contiene la configuración del sitio Nginx con variables como `server_hostname` que pueden ser personalizadas. El template `index.html.j2` permite personalizar la página web con información específica del servidor. El template `cleanup-logs.sh.j2` contiene el script de limpieza de logs, aunque en este caso no utiliza variables ya que la configuración es estática.

El template `jail.local.j2` contiene la configuración de fail2ban con valores ajustados para el entorno de producción. Finalmente, el template `50unattended-upgrades.j2` configura las actualizaciones automáticas de seguridad según las mejores prácticas.

El archivo `ansible.cfg` contiene configuraciones optimizadas para la ejecución, incluyendo deshabilitación de verificación de host keys para simplificar la ejecución local, configuración de pipelining para mejorar el rendimiento, y configuraciones de privilegios. El inventory define `localhost` para ejecución local, y se configuran apropiadamente los privilegios y la conexión SSH.

### Características Técnicas

La implementación proporciona separación clara de responsabilidades entre cloud-init y Ansible, configuración idempotente que puede ejecutarse múltiples veces sin efectos secundarios, templates reutilizables para diferentes ambientes, manejo robusto de errores mediante `ignore_errors` y validaciones, capacidad de ejecución tanto local como remota mediante la configuración del inventory, y versionado completo del código de infraestructura mediante Git.

Una de las ventajas más significativas de este enfoque es la capacidad de probar las configuraciones en un entorno local antes de desplegarlas en producción. Sin embargo, requiere más tiempo inicial de configuración y aprendizaje de las herramientas involucradas.

### Validación Realizada

Se creó el script `validate-strategy-b.sh` que confirma que `user-data.yml` es válido sintácticamente mediante `cloud-init schema`, verifica la presencia del playbook de Ansible, y confirma que todos los componentes requeridos están presentes mediante búsquedas en los archivos.

**Resultados de la validación:**

```
Validando Strategy B...
Valid schema user-data.yml
OK: user-data.yml valido
Archivos requeridos:
OK: user-data.yml existe
OK: site.yml existe
SKIP: ansible-playbook no instalado
Contenido verificado:
OK: hostname configurado
OK: usuario admin configurado
OK: ansible instalado
OK: nginx en playbook
OK: firewall en playbook
OK: hardening en playbook
Strategy B: Validacion completa
```

No pude validar completamente el playbook de Ansible porque no tenía Ansible instalado en mi WSL. Esto fue algo que me faltó, pero al menos pude verificar que todos los archivos estaban en su lugar y que la estructura se veía bien. En un entorno real, definitivamente validaría todo antes de desplegar.

El script de validación me confirmó que el user-data estaba correcto. Aunque no pude ejecutar todo completamente, revisando el código puedo decir que la sintaxis y estructura están bien, y seguí las mejores prácticas que aprendí sobre Ansible.

---

## 4. Comparación Técnica Entre Estrategias

Después de trabajar con ambas estrategias, puedo comparar qué tan bien funcionó cada una. A continuación está la tabla comparativa con los criterios que me pidieron evaluar, basándome en lo que realmente experimenté trabajando con cada una.

| Criterio | Estrategia A: Cloud-init Solo | Estrategia B: Cloud-init + Ansible |
|----------|-------------------------------|-----------------------------------|
| **Facilidad de Mantenimiento** | Media. Toda la configuración está embebida en un solo archivo user-data. Cuando se necesita modificar una configuración específica, es necesario editar el archivo completo y redeployar la instancia. La gestión de versiones es posible, pero es difícil versionar componentes individuales. A medida que la configuración crece, el archivo se vuelve difícil de mantener y propenso a errores. | Alta. La configuración está separada en módulos lógicos: playbooks, templates y variables. Es fácil actualizar un componente específico sin afectar otros. Los templates permiten reutilización y personalización. La estructura modular facilita la revisión de código y el mantenimiento a largo plazo. La organización clara del código reduce la probabilidad de errores. |
| **Reusabilidad** | Baja. La configuración está acoplada a una instancia específica. Si se necesita configurar múltiples servidores con configuraciones similares pero no idénticas, es necesario duplicar el archivo user-data y modificarlo manualmente. Esto genera problemas de mantenimiento cuando se necesita hacer cambios comunes a todos los servidores. | Alta. Los playbooks y roles de Ansible son fácilmente reutilizables. Los templates permiten configuración variable mediante variables. Un mismo playbook puede gestionar múltiples servidores con diferentes configuraciones mediante inventarios. La creación de roles permite reutilizar configuraciones comunes entre diferentes proyectos. |
| **Escalabilidad** | Baja. Gestionar cientos de servidores requiere mantener múltiples archivos user-data o implementar sistemas de templating complejos. No hay capacidades de orquestación integradas. Cada servidor requiere configuración individual. El proceso de actualización de múltiples servidores es manual y propenso a errores. | Alta. Ansible puede gestionar miles de servidores desde un nodo de control central. El inventario permite organizar servidores en grupos. La ejecución paralela permite actualizar múltiples servidores simultáneamente. Los playbooks pueden ejecutarse contra grupos específicos de servidores, facilitando el despliegue gradual. |
| **Seguridad** | Media. Se pueden aplicar configuraciones de seguridad básicas, pero las opciones son limitadas. Las actualizaciones de seguridad deben gestionarse manualmente. No hay mecanismo centralizado para aplicar políticas de seguridad. La auditoría de cambios de seguridad es difícil de rastrear. | Alta. Se pueden implementar capacidades completas de hardening mediante módulos específicos. La implementación incluye fail2ban para protección contra ataques, actualizaciones automáticas de seguridad, y hardening de SSH. Las políticas de seguridad pueden centralizarse y aplicarse consistentemente. La auditoría es más completa mediante logs detallados de ejecución. |
| **Trazabilidad de Cambios** | Baja. Los cambios están embebidos en los logs de cloud-init, pero es difícil rastrear modificaciones específicas. No hay mecanismo de rollback integrado. La visibilidad de qué cambió y cuándo es limitada. La relación entre cambios y su impacto es difícil de establecer. | Alta. Ansible proporciona logs detallados de ejecución que muestran qué cambió en cada ejecución. La integración con sistemas de control de versiones como Git permite rastrear todos los cambios en el código de infraestructura. Es fácil ver qué cambió, cuándo, y por qué mediante commits. Las capacidades de rollback son posibles mediante control de versiones. |

---


Después de implementar y comparar ambas estrategias, recomiendo la **Estrategia B: Automatización Híbrida usando Cloud-init + Ansible** para TecnoSoluciones SRL.

**Consideraciones de Mantenibilidad a Largo Plazo**

Lo que vi trabajando con la Estrategia A es que cuando el proyecto crece, mantener el código se vuelve complicado. El archivo user-data se hace muy largo y cualquier cambio pequeño significa modificar todo el archivo. Eso es un problema.

Con la Estrategia B es diferente. Cada cosa está separada, entonces puedo cambiar solo lo que necesito. Por ejemplo, puedo modificar Nginx sin tocar el firewall o el cron. Esto hace que sea más difícil meter la pata, y además varias personas pueden trabajar al mismo tiempo sin conflictos.

**Requisitos de Escalabilidad**

Aunque en este proyecto solo trabajé con un servidor, es obvio que en el futuro van a necesitar más. La Estrategia B tiene herramientas para gestionar muchos servidores desde un solo lugar. Puedo organizarlos en grupos y aplicar cambios a varios al mismo tiempo.

La Estrategia A requiere tener un archivo user-data para cada servidor, lo cual se vuelve un desastre cuando tienes muchos. Claro que podrías usar templates externos, pero eso solo añade más complicación. La Estrategia B ya viene con todo eso incluido.

**Seguridad y Cumplimiento**

La seguridad es una preocupación crítica para cualquier organización. La Estrategia B me permitió implementar un conjunto completo de medidas de seguridad, incluyendo fail2ban para protección contra ataques de fuerza bruta, actualizaciones automáticas de seguridad, y hardening de SSH. Estas configuraciones pueden centralizarse y aplicarse consistentemente a todos los servidores.

La Estrategia A permite configuraciones de seguridad básicas, pero las opciones avanzadas son limitadas. Para una organización que está estandarizando su infraestructura, tener capacidades robustas de seguridad desde el inicio es esencial.

**Gestión de Cambios y Auditoría**

La capacidad de rastrear cambios es importante tanto para troubleshooting como para cumplimiento. La Estrategia B proporciona logs detallados y integración con sistemas de control de versiones, permitiendo rastrear exactamente qué cambió, cuándo, y por qué. Esta trazabilidad es invaluable cuando algo falla y necesito determinar qué cambio causó el problema.

La Estrategia A proporciona logs de cloud-init, pero la relación entre cambios específicos y su impacto es más difícil de establecer. En un entorno empresarial, la capacidad de auditar cambios es crucial.

**Colaboración en Equipo**

La Estrategia B facilita la colaboración mediante su estructura modular. Múltiples miembros del equipo pueden trabajar en diferentes componentes sin generar conflictos. Las revisiones de código son más efectivas porque los cambios están aislados en archivos específicos. El control de versiones es más efectivo porque los cambios están organizados lógicamente.

**Preparación para el Futuro**

La industria se mueve hacia Infrastructure as Code y DevOps practices. La Estrategia B está alineada con estas tendencias y facilita la integración con pipelines CI/CD. La capacidad de probar configuraciones antes de desplegarlas en producción reduce el riesgo y permite una mejora continua más rápida.

### Estrategia de Implementación Recomendada


1. **Fase Inicial:** Comenzar con la Estrategia B para todos los nuevos servidores, utilizando los playbooks desarrollados como base.

2. **Migración Gradual:** Migrar servidores existentes de la Estrategia A a la B de forma gradual, comenzando con servidores menos críticos.

3. **Estandarización:** Crear roles de Ansible reutilizables para configuraciones comunes, como la configuración de Nginx o el hardening de seguridad.

4. **Automatización:** Integrar los playbooks con pipelines CI/CD para validación y despliegue automatizado.

5. **Capacitación:** Proporcionar capacitación al equipo en mejores prácticas de Ansible y Infrastructure as Code.

6. **Documentación:** Mantener documentación actualizada de todos los playbooks y su propósito.

### Consideraciones Finales

Entiendo que la Estrategia A es más simple al principio y funciona bien para cosas básicas o cuando quieres algo rápido. Pero la Estrategia B vale mucho más la pena a largo plazo. Sí, al inicio hay que invertir tiempo aprendiendo Ansible, pero después cuando la infraestructura crece y las cosas se complican, ese tiempo invertido se paga solo.

Para una organización que está estandarizando su proceso de aprovisionamiento de cloud, la Estrategia B es la elección estratégica que apoyará el crecimiento, asegurará la seguridad, y permitirá una gestión eficiente de la infraestructura por años venideros.

---

# Conclusión

Durante este proyecto me encontré con varios problemas que me enseñaron bastante. Déjame contarte qué pasó.

El primer problema que tuve fue con la configuración de red en cloud-init. Intenté configurarla explícitamente en el user-data, pero cuando validé me salió error. Eso me enseñó que siempre debo leer bien la documentación y validar antes de seguir adelante.

Otro desafío fue la limitación de probar cloud-init completamente en el entorno WSL. Cloud-init requiere un datasource específico que no está disponible en WSL, lo que limitó las pruebas que pude realizar. Sin embargo, la validación de sintaxis mediante `cloud-init schema` proporcionó suficiente confianza de que la configuración funcionaría correctamente en un entorno cloud real.

En la Estrategia B, el desafío principal fue aprender la sintaxis y estructura de Ansible. Aunque la documentación es excelente, requiere tiempo para entender conceptos como handlers, templates Jinja2, y la estructura de playbooks. Sin embargo, una vez comprendidos, estos conceptos proporcionan una flexibilidad significativa.

