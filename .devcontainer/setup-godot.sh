#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.4.1"
GODOT_TAG="4.4.1-stable"
GODOT_DIR="${HOME}/.local/share/godot"
BIN_DIR="${HOME}/.local/bin"
ANDROID_SDK="${ANDROID_HOME:-/opt/android-sdk}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${GODOT_DIR}" "${BIN_DIR}" "${ANDROID_SDK}/cmdline-tools"

echo "[1/4] Downloading Godot ${GODOT_VERSION} editor..."
curl -fL --retry 3 \
  "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
  -o "${TMP_DIR}/godot.zip"
unzip -q "${TMP_DIR}/godot.zip" -d "${TMP_DIR}/godot"
install -m 0755 "${TMP_DIR}/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "${BIN_DIR}/godot"

echo "[2/4] Installing matching Android export templates..."
curl -fL --retry 3 \
  "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
  -o "${TMP_DIR}/templates.tpz"
mkdir -p "${GODOT_DIR}/export_templates/${GODOT_VERSION}.stable"
unzip -q "${TMP_DIR}/templates.tpz" -d "${TMP_DIR}/export_templates"
if [ -d "${TMP_DIR}/export_templates/templates" ]; then
  cp -a "${TMP_DIR}/export_templates/templates/." "${GODOT_DIR}/export_templates/${GODOT_VERSION}.stable/"
else
  cp -a "${TMP_DIR}/export_templates/." "${GODOT_DIR}/export_templates/${GODOT_VERSION}.stable/"
fi

echo "[3/4] Installing Android command-line tools..."
curl -fL --retry 3 \
  "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
  -o "${TMP_DIR}/android-tools.zip"
mkdir -p "${TMP_DIR}/android-tools"
unzip -q "${TMP_DIR}/android-tools.zip" -d "${TMP_DIR}/android-tools"
mkdir -p "${ANDROID_SDK}/cmdline-tools/latest"
cp -a "${TMP_DIR}/android-tools/cmdline-tools/." "${ANDROID_SDK}/cmdline-tools/latest/"

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export PATH="${ANDROID_SDK}/cmdline-tools/latest/bin:${ANDROID_SDK}/platform-tools:${BIN_DIR}:${PATH}"

echo "[4/4] Installing SDK packages documented for Godot 4.4..."
yes | sdkmanager --sdk_root="${ANDROID_SDK}" --licenses >/dev/null
sdkmanager --sdk_root="${ANDROID_SDK}" \
  "platform-tools" \
  "build-tools;34.0.0" \
  "platforms;android-34" \
  "cmake;3.10.2.4988404" \
  "ndk;23.2.8568313"

echo
godot --version
echo "Setup finished. Android SDK: ${ANDROID_SDK}"
echo "Godot templates: ${GODOT_DIR}/export_templates/${GODOT_VERSION}.stable"
