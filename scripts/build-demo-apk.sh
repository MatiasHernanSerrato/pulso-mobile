#!/usr/bin/env bash
# Build de un APK de release que uso para pasarle a amigos como demo.
# NO es el build de store (ese va por Shorebird, ver README).
#
# Diferencias con un build normal:
#   - Define API_URL apuntando a produccion (fly.io) para que la demo pegue
#     contra algo real en vez de a localhost.
#   - Mete flavor "demo" en el versionName para no confundirlo con lo que
#     sube a Play.
#   - Hace split por ABI, que achica cada APK de ~55MB a ~22MB.
#   - Copia los artefactos a build/demo/ con nombres mas explicitos.

set -euo pipefail

API_URL="${API_URL:-https://pulso-api.fly.dev}"
OUT_DIR="build/demo"

echo ">> flutter pub get"
flutter pub get

echo ">> flutter clean"
flutter clean

echo ">> flutter build apk (release, split-per-abi, demo flavor)"
flutter build apk \
  --release \
  --split-per-abi \
  --dart-define=API_URL="${API_URL}" \
  --dart-define=BUILD_FLAVOR=demo

mkdir -p "${OUT_DIR}"
TS="$(date +%Y%m%d-%H%M)"
for abi in armeabi-v7a arm64-v8a x86_64; do
  src="build/app/outputs/flutter-apk/app-${abi}-release.apk"
  if [[ -f "${src}" ]]; then
    dst="${OUT_DIR}/pulso-demo-${TS}-${abi}.apk"
    cp "${src}" "${dst}"
    size=$(du -h "${dst}" | awk '{print $1}')
    echo "  ${dst}  (${size})"
  fi
done

echo ">> listo. apks en ${OUT_DIR}/"
