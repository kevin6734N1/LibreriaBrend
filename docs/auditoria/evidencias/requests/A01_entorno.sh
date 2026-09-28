#!/usr/bin/env bash
# FASE 2 - Auditoría LibreriaBrend
# A.01 - Verificación de entorno (solo lectura)
# POLÍTICA DE HIGIENE: el valor literal de la contraseña detectada en el artefacto
# desplegado se REDACTa en la evidencia. El hallazgo sigue siendo reproducible con
# el comando indicado en FASE2_INFORME.md (§2, R-01), ejecutado localmente.
CTX="http://localhost:8080/LibreriaBrend"
TC="/home/kevin/apache-tomcat-11.0.0-M24"

echo "===== A.01.1 Fecha de ejecución ====="
date --iso-8601=seconds

echo
echo "===== A.01.2 Puerto 8080 a la escucha ====="
ss -ltnp 2>/dev/null | grep -E ":8080" || echo "NO ESCUCHA 8080"

echo
echo "===== A.01.3 Proceso Tomcat ====="
pgrep -af "org.apache.catalina.startup.Bootstrap" | head -3

echo
echo "===== A.01.4 Despliegue (webapps) ====="
ls -la "$TC/webapps/"

echo
echo "===== A.01.5 Herramientas disponibles ====="
java -version 2>&1 | head -1
javac -version 2>&1
node --version 2>&1
curl --version 2>&1 | head -1
mariadb --version 2>&1

echo
echo "===== A.01.6 Cabeceras de la aplicación ====="
curl -s -I -m 10 "$CTX/" | sed -E 's/JSESSIONID=[A-F0-9]*/JSESSIONID=<REDACTADO>/'

echo
echo "===== A.01.7 A qué base de datos apunta la app desplegada (contenido de la clase compilada) ====="
echo "Comando reproducible localmente:"
echo "  grep -a -o -E 'jdbc:mysql://[^\"]*' \$TC/webapps/LibreriaBrend/WEB-INF/classes/libreria/util/ConexionBD.class"
echo "Resultado (URL de conexión embebida en el bytecode):"
grep -a -o -E 'jdbc:mysql://[^" ]*' "$TC/webapps/LibreriaBrend/WEB-INF/classes/libreria/util/ConexionBD.class" \
  | tr -d '\000-\010\013\014\016-\037' | head -1
echo "Literales de credenciales embebidos en la MISMA clase:"
echo "  [usuario]     root"
echo "  [contraseña]  <REDACTADO — valor omitido por política de higiene del repositorio>"
echo "  (Las constantes USUARIO y PASSWORD se declaran como literales en ConexionBD.java:29-30"
echo "   y quedan en el constant pool de la clase compilada.)"

echo
echo "-- ficheros de configuración externos (context.xml / .properties / JNDI) --"
find "$TC/webapps/LibreriaBrend" -maxdepth 3 \( -name "context.xml" -o -name "*.properties" \) -print
echo "(vacío = NO existe configuración externa de BD: el nombre de la BD y las credenciales están compilados en la clase)"
grep -n "Resource\|jdbc" "$TC/conf/context.xml" "$TC/conf/server.xml" 2>/dev/null | grep -v GlobalNamingResources || echo "(sin DataSource JNDI con la BD de la aplicación en la configuración de Tomcat)"

echo
echo "===== A.01.8 Bases de datos existentes en el servidor MariaDB ====="
# La contraseña NO se escribe en este script: se toma del entorno del operador
# (export MYSQL_PWD='<credencial del proyecto>' antes de ejecutarlo).
MYSQL_PWD="${MYSQL_PWD:?exporta MYSQL_PWD antes de ejecutar este script}" mariadb -h 127.0.0.1 -P 3306 -u root -N \
  -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME LIKE 'libreria%';" 2>/dev/null
echo "(una sola BD 'libreria_brenda': NO existe base de datos de prueba)"

echo
echo "===== A.01.9 Ficheros de log existentes ====="
find "$TC/logs" -type f | sort
echo "-- catalina.out / localhost.<fecha>.log --"
ls "$TC/logs/catalina.out" 2>/dev/null || echo "NO EXISTE catalina.out"
ls "$TC"/logs/localhost.log* "$TC"/logs/localhost.2026-*.log 2>/dev/null || echo "NO EXISTE localhost.<fecha>.log (no hay log persistente de errores)"
echo "-- destino de stdout/stderr del proceso Tomcat --"
PID=$(pgrep -f 'org.apache.catalina.startup.Bootstrap' | head -1)
ls -l /proc/$PID/fd/1 /proc/$PID/fd/2 2>/dev/nullecho
 echo "===== A.01.10 Grep de SEVERE/ERROR/WARN en logs disponibles ====="
grep -rInE "SEVERE|ERROR|WARN|Exception" "$TC/logs/" 2>/dev/null || echo "(sin coincidencias SEVERE/ERROR/WARN/Exception en los logs disponibles)"

echo
echo "===== A.01.11 Estado del repositorio y verificación del remoto ====="
cd /home/kevin/proyectos/LibreriaBrend || exit 1
echo "-- HEAD, rama y árbol de trabajo --"
printf "HEAD:  "; git rev-parse HEAD
git status --porcelain; echo "(status vacío = árbol limpio)"
printf "Rama:  "; git branch --show-current
echo "-- último commit --"
git log -1 --pretty="%H | %ad | %s" --date=iso
echo "-- commit declarado por docs/REGISTRO_CAMBIOS.md como estado actual --"
grep -oE '\| 2026-09-[0-9]{2} \| `[0-9a-f]{7}` \| \*\*Paso 3b|`54a810c`' docs/REGISTRO_CAMBIOS.md | head -2
grep -n "54a810c" docs/REGISTRO_CAMBIOS.md | head -3
echo "-- remoto real (git ls-remote) --"
timeout 25 git ls-remote origin 2>&1 | head -5
echo "-- distancia entre HEAD y el commit declarado en el registro --"
printf "commits de diferencia: "; git rev-list --count 54a810c..HEAD 2>/dev/null || echo "(hash no hallado)"
git diff --stat 54a810c..HEAD | tail -3
