#!/usr/bin/env sh
set -eu

GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.24.3}"
HADOLINT_VERSION="${HADOLINT_VERSION:-2.14.0}"
GITLEAKS_BASE_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}"
HADOLINT_BASE_URL="https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}"

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/../.." && pwd)"
tools_dir="${repo_root}/.tools"
mkdir -p "${tools_dir}"

log() {
  printf '%s\n' "$*"
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

download() {
  url="$1"
  out="$2"

  log "Downloading ${url}"
  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$out" "$url"
  else
    die "curl 또는 wget이 필요합니다."
  fi
}

sha256_file() {
  path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print tolower($1)}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print tolower($1)}'
  elif command -v certutil.exe >/dev/null 2>&1; then
    certutil.exe -hashfile "$path" SHA256 | awk 'NF == 1 && $1 ~ /^[0-9A-Fa-f]{64}$/ {print tolower($1); exit}'
  else
    die "checksum 검증을 위해 sha256sum, shasum, certutil.exe 중 하나가 필요합니다."
  fi
}

expected_checksum() {
  checksum_file="$1"
  asset="$2"

  awk -v asset="$asset" '
    {
      name = $2
      sub(/^\*/, "", name)
      if (name == asset) {
        print tolower($1)
        found = 1
        exit
      }
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$checksum_file"
}

verify_checksum() {
  file_path="$1"
  checksum_file="$2"
  asset="$3"

  expected="$(expected_checksum "$checksum_file" "$asset")" || die "checksum 파일에서 ${asset} 항목을 찾지 못했습니다."
  actual="$(sha256_file "$file_path")"

  if [ "$actual" != "$expected" ]; then
    die "checksum 검증 실패: ${asset} expected=${expected} actual=${actual}"
  fi
}

normalize_os() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' macos ;;
    Linux) printf '%s\n' linux ;;
    MINGW*|MSYS*|CYGWIN*) printf '%s\n' windows ;;
    *) die "지원하지 않는 OS입니다: $(uname -s)" ;;
  esac
}

normalize_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf '%s\n' x64 ;;
    arm64|aarch64) printf '%s\n' arm64 ;;
    *) die "지원하지 않는 CPU architecture입니다: $(uname -m)" ;;
  esac
}

extract_archive() {
  archive="$1"
  dest="$2"

  mkdir -p "$dest"
  case "$archive" in
    *.tar.gz)
      tar -xzf "$archive" -C "$dest"
      ;;
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q "$archive" -d "$dest"
      elif tar -tf "$archive" >/dev/null 2>&1; then
        tar -xf "$archive" -C "$dest"
      else
        die "zip 압축 해제를 위해 unzip 또는 zip을 지원하는 tar가 필요합니다."
      fi
      ;;
    *)
      die "지원하지 않는 archive 형식입니다: ${archive}"
      ;;
  esac
}

gitleaks_plan() {
  os="$1"
  arch="$2"

  case "$os" in
    windows)
      [ "$arch" = x64 ] || die "gitleaks Windows 자동 다운로드는 x64만 지원합니다."
      asset="gitleaks_${GITLEAKS_VERSION}_windows_x64.zip"
      ;;
    macos)
      case "$arch" in
        x64) asset="gitleaks_${GITLEAKS_VERSION}_darwin_x64.tar.gz" ;;
        arm64) asset="gitleaks_${GITLEAKS_VERSION}_darwin_arm64.tar.gz" ;;
      esac
      ;;
    linux)
      case "$arch" in
        x64) asset="gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" ;;
        arm64) asset="gitleaks_${GITLEAKS_VERSION}_linux_arm64.tar.gz" ;;
      esac
      ;;
  esac

  printf '%s|%s|%s\n' "${asset}" "${GITLEAKS_BASE_URL}/${asset}" "${GITLEAKS_BASE_URL}/gitleaks_${GITLEAKS_VERSION}_checksums.txt"
}

hadolint_plan() {
  os="$1"
  arch="$2"

  case "$os" in
    windows)
      [ "$arch" = x64 ] || die "hadolint Windows 자동 다운로드는 x64만 지원합니다."
      asset="hadolint-windows-x86_64.exe"
      ;;
    macos)
      case "$arch" in
        x64) asset="hadolint-macos-x86_64" ;;
        arm64) asset="hadolint-macos-arm64" ;;
      esac
      ;;
    linux)
      case "$arch" in
        x64) asset="hadolint-linux-x86_64" ;;
        arm64) asset="hadolint-linux-arm64" ;;
      esac
      ;;
  esac

  printf '%s|%s|%s\n' "${asset}" "${HADOLINT_BASE_URL}/${asset}" "${HADOLINT_BASE_URL}/${asset}.sha256"
}

install_gitleaks() {
  os="$1"
  arch="$2"
  exe_suffix=""
  [ "$os" = windows ] && exe_suffix=".exe"
  target="${tools_dir}/gitleaks${exe_suffix}"

  if [ -f "$target" ]; then
    log "Using existing ${target}"
    return
  fi

  plan="$(gitleaks_plan "$os" "$arch")"
  asset="$(printf '%s' "$plan" | cut -d '|' -f 1)"
  url="$(printf '%s' "$plan" | cut -d '|' -f 2)"
  checksum_url="$(printf '%s' "$plan" | cut -d '|' -f 3)"
  temp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t cloudnative-security)"
  archive_path="${temp_dir}/${asset}"
  checksum_path="${temp_dir}/checksums.txt"
  extract_dir="${temp_dir}/extract"

  trap 'rm -rf "${temp_dir}"' EXIT HUP INT TERM
  download "$url" "$archive_path"
  download "$checksum_url" "$checksum_path"
  verify_checksum "$archive_path" "$checksum_path" "$asset"
  extract_archive "$archive_path" "$extract_dir"

  binary="$(find "$extract_dir" -type f -name "gitleaks${exe_suffix}" | head -n 1)"
  [ -n "$binary" ] || die "gitleaks binary를 archive에서 찾지 못했습니다: ${asset}"

  cp "$binary" "$target"
  chmod +x "$target"
  log "Installed ${target}"
  rm -rf "$temp_dir"
  trap - EXIT HUP INT TERM
}

install_hadolint() {
  os="$1"
  arch="$2"
  exe_suffix=""
  [ "$os" = windows ] && exe_suffix=".exe"
  target="${tools_dir}/hadolint${exe_suffix}"

  if [ -f "$target" ]; then
    log "Using existing ${target}"
    return
  fi

  plan="$(hadolint_plan "$os" "$arch")"
  asset="$(printf '%s' "$plan" | cut -d '|' -f 1)"
  url="$(printf '%s' "$plan" | cut -d '|' -f 2)"
  checksum_url="$(printf '%s' "$plan" | cut -d '|' -f 3)"
  temp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t cloudnative-security)"
  download_path="${temp_dir}/${asset}"
  checksum_path="${temp_dir}/${asset}.sha256"

  trap 'rm -rf "${temp_dir}"' EXIT HUP INT TERM
  download "$url" "$download_path"
  download "$checksum_url" "$checksum_path"
  verify_checksum "$download_path" "$checksum_path" "$asset"

  cp "$download_path" "$target"
  chmod +x "$target"
  log "Installed ${target}"
  rm -rf "$temp_dir"
  trap - EXIT HUP INT TERM
}

os="$(normalize_os)"
arch="$(normalize_arch)"

install_gitleaks "$os" "$arch"
install_hadolint "$os" "$arch"

log "Security tools are ready in ${tools_dir}"
