#!/bin/sh
# ----------------------------------------------------------------------------
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Apache Maven Wrapper startup batch script, version 3.3.2
#
# Optional ENV vars
# -----------------
#   JAVA_HOME - location of a JDK home dir, required when download maven via java source
#   MVNW_REPOURL - repo url base for downloading maven distribution
#   MVNW_USERNAME/MVNW_PASSWORD - user and password for downloading maven
#   MVNW_VERBOSE - true: enable verbose log; debug: trace the mvnw script; others: silence the output
# ----------------------------------------------------------------------------

#!/bin/bash
set -euf

# Si la variable de entorno MVNW_VERBOSE está configurada a debug, habilitar el modo detallado
[ "${MVNW_VERBOSE-}" != debug ] || set -x

# Soporte específico para el sistema operativo
native_path() { printf %s\\n "$1"; }
case "$(uname)" in
CYGWIN* | MINGW*)
  # Convertir JAVA_HOME de Windows a formato Unix
  [ -z "${JAVA_HOME-}" ] || JAVA_HOME="$(cygpath --unix "$JAVA_HOME")"
  native_path() { cygpath --path --windows "$1"; }
  ;;
esac

# Función para configurar JAVA_HOME y comprobar si existe Java
set_java_home() {
  if [ -n "${JAVA_HOME-}" ]; then
    if [ -x "$JAVA_HOME/jre/sh/java" ]; then
      JAVACMD="$JAVA_HOME/jre/sh/java"
      JAVACCMD="$JAVA_HOME/jre/sh/javac"
    else
      JAVACMD="$JAVA_HOME/bin/java"
      JAVACCMD="$JAVA_HOME/bin/javac"

      if [ ! -x "$JAVACMD" ] || [ ! -x "$JAVACCMD" ]; then
        echo "JAVA_HOME no está configurado correctamente. $JAVA_HOME/bin/java o $JAVA_HOME/bin/javac no existen." >&2
        return 1
      fi
    fi
  else
    JAVACMD="$(command -v java)" || :
    JAVACCMD="$(command -v javac)" || :

    if [ ! -x "$JAVACMD" ] || [ ! -x "$JAVACCMD" ]; then
      echo "No se encuentra Java ni en el PATH ni configurado en JAVA_HOME. No se puede ejecutar mvnw." >&2
      return 1
    fi
  fi
}

# Función para calcular el hash de una cadena como String::hashCode en Java
hash_string() {
  str="${1:-}" h=0
  while [ -n "$str" ]; do
    char="${str%"${str#?}"}"
    h=$(((h * 31 + $(LC_CTYPE=C printf %d "'$char")) % 4294967296))
    str="${str#?}"
  done
  printf %x\\n $h
}

# Función para imprimir detalles de la ejecución si se configura el modo verbose
verbose() { :; }
[ "${MVNW_VERBOSE-}" != true ] || verbose() { printf %s\\n "${1-}"; }

# Función para terminar con un mensaje de error
die() {
  printf %s\\n "$1" >&2
  exit 1
}

# Función para eliminar espacios y saltos de línea
trim() {
  printf "%s" "${1}" | tr -d '[:space:]'
}

# Leer el archivo de configuración maven-wrapper.properties para obtener la URL de distribución de Maven
while IFS="=" read -r key value; do
  case "${key-}" in
    distributionUrl) distributionUrl=$(trim "${value-}") ;;
    distributionSha256Sum) distributionSha256Sum=$(trim "${value-}") ;;
  esac
done <"${0%/*}/.mvn/wrapper/maven-wrapper.properties"

# Verificar si la URL de distribución está definida
[ -n "${distributionUrl-}" ] || die "No se puede leer la propiedad distributionUrl en .mvn/wrapper/maven-wrapper.properties"

# Determinar la URL correcta de Maven dependiendo del sistema operativo y arquitectura
case "${distributionUrl##*/}" in
  maven-mvnd-*bin.*)
    MVN_CMD=mvnd.sh _MVNW_REPO_PATTERN=/maven/mvnd/
    case "$(uname -a)" in
      *AMD64:CYGWIN* | *AMD64:MINGW*) distributionPlatform=windows-amd64 ;;
      :Darwin*x86_64) distributionPlatform=darwin-amd64 ;;
      :Darwin*arm64) distributionPlatform=darwin-aarch64 ;;
      :Linux*x86_64*) distributionPlatform=linux-amd64 ;;
      *) distributionPlatform=linux-amd64 ;;
    esac
    distributionUrl="${distributionUrl%-bin.*}-$distributionPlatform.zip"
    ;;
  maven-mvnd-*) MVN_CMD=mvnd.sh _MVNW_REPO_PATTERN=/maven/mvnd/ ;;
  *) MVN_CMD="mvn${0##*/mvnw}" _MVNW_REPO_PATTERN=/org/apache/maven/ ;;
esac

# Calcular la ubicación de MAVEN_HOME según la distribución de Maven
MAVEN_USER_HOME="${MAVEN_USER_HOME:-${HOME}/.m2}"
MAVEN_HOME="${MAVEN_USER_HOME}/wrapper/dists/$(hash_string "$distributionUrl")"

# Si MAVEN_HOME ya existe, ejecutar Maven directamente
if [ -d "$MAVEN_HOME" ]; then
  verbose "MAVEN_HOME encontrado en $MAVEN_HOME"
  exec_maven "$@"
fi

# Validar la URL de distribución
[ -z "${MVNW_REPOURL-}" ] || distributionUrl="$MVNW_REPOURL$_MVNW_REPO_PATTERN${distributionUrl#*"$_MVNW_REPO_PATTERN"}"
distributionUrlName="${distributionUrl##*/}"

# Descargar e instalar Maven si no se encuentra
TMP_DOWNLOAD_DIR="$(mktemp -d)"
trap "rm -rf -- $TMP_DOWNLOAD_DIR" HUP INT TERM EXIT

verbose "Descargando Maven desde $distributionUrl"
wget --quiet "$distributionUrl" -O "$TMP_DOWNLOAD_DIR/$distributionUrlName" || die "Falló la descarga de Maven."

# Verificación del checksum si es necesario
if [ -n "${distributionSha256Sum-}" ]; then
  echo "$distributionSha256Sum  $TMP_DOWNLOAD_DIR/$distributionUrlName" | sha256sum -c || die "Error al verificar el checksum de Maven."
fi

# Descomprimir el archivo y moverlo a MAVEN_HOME
unzip -q "$TMP_DOWNLOAD_DIR/$distributionUrlName" -d "$TMP_DOWNLOAD_DIR" || die "Error al descomprimir Maven."
mv -- "$TMP_DOWNLOAD_DIR/$distributionUrlName" "$MAVEN_HOME" || die "Error al mover Maven a $MAVEN_HOME"

# Limpiar y ejecutar Maven
trap - HUP INT TERM EXIT
exec_maven "$@"
