#!/usr/bin/env bash
set -euo pipefail

log() {
  printf "%s\n" "==> $*"
}

warn() {
  printf "%s\n" "WARN: $*" >&2
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

install_homebrew_if_missing() {
  if has_command brew; then
    log "Homebrew already installed: $(command -v brew)"
    return
  fi

  if ! is_macos; then
    warn "Homebrew is missing and this installer only supports automatic Homebrew installation on macOS."
    return
  fi

  log "Homebrew is missing."
  read -r -p "Install Homebrew now? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES)
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ;;
    *)
      warn "Skipped Homebrew installation."
      ;;
  esac
}

install_brew_package() {
  local package="$1"

  if brew list --formula "$package" >/dev/null 2>&1 || brew list --cask "$package" >/dev/null 2>&1; then
    log "$package already installed."
    return
  fi

  log "Installing $package"
  brew install "$package"
}

install_brew_cask() {
  local package="$1"

  if brew list --cask "$package" >/dev/null 2>&1; then
    log "$package already installed."
    return
  fi

  log "Installing cask $package"
  brew install --cask "$package"
}

check_vmware_fusion() {
  if [[ -d "/Applications/VMware Fusion.app" ]]; then
    log "VMware Fusion found."
  else
    warn "VMware Fusion was not found in /Applications. Install VMware Fusion manually before running local VMs."
  fi
}

install_docker_if_missing() {
  if has_command docker; then
    log "Docker already installed: $(command -v docker)"
    return
  fi

  if ! has_command brew; then
    warn "Docker is missing and Homebrew is unavailable. Install Docker Desktop or another Docker runtime manually."
    return
  fi

  log "Installing Docker Desktop"
  install_brew_cask docker || warn "Automatic Docker Desktop install failed. Follow the manual install guide."
}

install_vagrant_plugin() {
  if ! has_command vagrant; then
    warn "Vagrant command is missing. Cannot install vagrant-vmware-desktop plugin."
    return
  fi

  if vagrant plugin list | grep -q "vagrant-vmware-desktop"; then
    log "vagrant-vmware-desktop plugin already installed."
    return
  fi

  log "Installing vagrant-vmware-desktop plugin"
  vagrant plugin install vagrant-vmware-desktop
}

add_default_box() {
  if ! has_command vagrant; then
    warn "Vagrant command is missing. Cannot add default box."
    return
  fi

  local box="${LOCAL_VAGRANT_BOX:-bento/ubuntu-22.04}"
  local provider="${LOCAL_VAGRANT_PROVIDER:-vmware_desktop}"

  if vagrant box list | awk '{print $1}' | grep -qx "$box"; then
    log "Vagrant box already exists: $box"
    return
  fi

  log "Adding Vagrant box: $box ($provider)"
  vagrant box add "$box" --provider "$provider"
}

if ! is_macos; then
  warn "This automatic installer is intended for macOS with VMware Fusion."
fi

install_homebrew_if_missing

if has_command brew; then
  install_docker_if_missing
  install_brew_cask vagrant
  install_brew_cask vagrant-vmware-utility || warn "Automatic VMware Utility cask install failed. Follow the manual install guide in README.md."
  install_brew_package ansible
  install_brew_package helm
else
  warn "Homebrew is unavailable. Skipping automatic CLI installation."
fi

check_vmware_fusion
install_vagrant_plugin
add_default_box

log "Tool installation step completed. Run: make check-local-dev-tools && make check-tools"
