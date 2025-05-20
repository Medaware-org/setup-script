#!/bin/bash

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "  Medaware Local Development"
echo "           Setup"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

if ! command -v git; then
  echo "Please make sure 'git' is installed before invoking this script."
  exit
fi

if ! command -v wget; then
  echo "Please make sure 'wget' is installed before invoking this script."
  exit
fi

if ! command -v docker; then
  echo "Please make sure 'docker' is installed before invoking this script."
  exit
fi

if ! command -v npm; then
  echo "Please make sure 'npm' is installed before invoking this script."
  exit
fi

if ! wget -q --spider http://www.gentoo.org; then
  echo "Please connect to the internet before invoking this script."
  exit
fi

MEDAWARE_PATH="$(pwd)"
MEDAWARE_DIR="medaware"

if [ -d "${MEDAWRE_DIR}" ]; then
  echo "The directory '${MEDAWARE_DIR}' already exists. Aborting."
  exit
fi

function fail_reset() {
  printf "\n\n ** Failed setting up the Medaware environment. Cleaning up .. **\n\n"
  cd "${MEDAWARE_PATH}" || exit
  rm -rf "${MEDAWARE_DIR}"
  exit
}

function dependency() {
  if [ "$#" -ne 3 ]; then
    echo "== Internal error: dependency: Invalid number of function parameters =="
    fail_reset
  fi

  git clone "$1" "$2"
  cd "$2" || fail_reset
  git fetch origin "$3"
  git checkout "$3"

  if [ ! -f "gradlew" ]; then
    echo "== Error: dependency: Could not find gradle wrapper in the dependency folder of dependency '$2' =="
    fail_reset
  fi

  if ! ./gradlew publish; then
    echo "== Error: dependency: Building '$2' failed. =="
    fail_reset
  fi

  echo "++ OK: Dependency installed: $2 ++"

  cd "${MEDAWARE_PATH}/${MEDAWARE_DIR}" || fail_reset
}

mkdir "${MEDAWARE_DIR}"
cd "${MEDAWARE_DIR}" || fail_reset

echo ""
echo "##############################"
echo "  Installing MaW Dependencies"
echo "##############################"
echo ""

dependency "https://github.com/Medaware-org/anterogradia" "anterogradia" "stable"
dependency "https://github.com/Medaware-org/antg-avis" "avis" "main"

echo ""
echo "##############################"
echo "      Setting up Services"
echo "##############################"
echo ""

git clone https://github.com/Medaware-org/staging-env services
cd services || fail_reset
docker container stop maw-minio && docker container remove maw-minio
docker container stop maw-catalyst-db && docker container remove maw-catalyst-db
docker compose up -d

cd "${MEDAWARE_PATH}/${MEDAWARE_DIR}" || fail_reset

echo ""
echo "##############################"
echo "      Installing Catalyst"
echo "##############################"
echo ""

git clone https://github.com/Medaware-org/catalyst catalyst
cd catalyst || fail_reset
git submodule init
git submodule update
if ! ./gradlew build --refresh-dependencies -x test; then
  echo "== Error: Could not build Catalyst =="
  fail_reset
fi

cd "${MEDAWARE_PATH}/${MEDAWRE_DIR}" || fail_reset

echo ""
echo "##############################"
echo "       Install Tangential"
echo "##############################"
echo ""

git clone https://github.com/Medaware-org/tangential tangential
cd tangential || fail_reset
npm i

echo ""
echo "##############################"
echo "         -= Done =-"
echo "##############################"
echo ""
