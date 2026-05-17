# Manual Install

자동 설치가 실패하거나 특정 도구를 직접 설치해야 할 때 사용하는 문서다.

## 1. Docker runtime

Docker는 서비스 이미지를 build하고 control-plane VM의 local registry(`10.10.10.10:5000`)에 push하기 위해 필요하다. 현재 표준 Kubernetes 흐름에서는 Docker Compose가 필요하지 않다.

macOS:

```bash
brew install --cask docker
```

설치 후 Docker Desktop을 한 번 실행하고 확인한다.

```bash
docker --version
docker version
```

Windows + WSL에서는 Docker Desktop의 WSL integration을 켠 뒤 WSL에서 확인한다.

```bash
docker version
```

## 2. VMware Workstation / Fusion

Windows는 VMware Workstation, macOS는 VMware Fusion을 설치하고 한 번 실행해 둔다. Vagrant가 VM을 만들 때 VMware backend를 사용한다.

macOS 확인:

```bash
ls /Applications | grep -i "VMware Fusion"
```

## 3. Homebrew

macOS에서 Vagrant, Ansible 같은 CLI 도구 설치에 사용한다.

```bash
brew --version
```

Homebrew가 없다면 먼저 설치한다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 4. Vagrant

Vagrant는 로컬 VM을 코드로 만들고 삭제하는 도구다.

macOS:

```bash
brew install --cask vagrant
```

Windows에서는 Vagrant installer를 사용한다.

확인:

```bash
vagrant --version
```

## 5. Vagrant VMware provider

Vagrant가 VMware를 제어하려면 VMware provider plugin과 VMware Utility가 필요하다.

macOS VMware Utility:

```bash
brew install --cask vagrant-vmware-utility
```

Vagrant VMware provider plugin:

```bash
vagrant plugin install vagrant-vmware-desktop
```

확인:

```bash
vagrant plugin list | grep vagrant-vmware-desktop
```

VMware Utility cask 설치가 실패하면 HashiCorp의 Vagrant VMware Utility 다운로드 페이지에서 OS에 맞는 패키지를 직접 설치한다.

## 6. Ansible

Ansible은 생성된 VM에 SSH로 접속해서 서버 초기 설정, kubeadm cluster bootstrap, registry/Kong/MetalLB 설치를 자동 수행한다.

macOS:

```bash
brew install ansible
```

WSL Ubuntu:

```bash
sudo apt update
sudo apt install -y ansible make
```

확인:

```bash
ansible --version
ansible-playbook --version
```

## 7. Vagrant box

기본 box는 `.env.example`에 `bento/ubuntu-22.04`로 잡혀 있다.

```bash
vagrant box add bento/ubuntu-22.04 --provider vmware_desktop
```

Apple Silicon Mac에서는 VMware Fusion이 ARM guest를 실행하므로, 위 box가 환경에 맞지 않으면 ARM64를 지원하는 Ubuntu VMware box로 바꾸고 `.env`의 `LOCAL_VAGRANT_BOX` 값을 수정한다.

## 8. 최종 확인

```bash
cd infra/cluster
make check-tools
make check-docker-registry-proxy
```
