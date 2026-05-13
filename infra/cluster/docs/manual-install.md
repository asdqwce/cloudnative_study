# Manual Install

자동 설치가 실패하거나 특정 도구를 직접 설치해야 할 때 사용하는 문서다.

## 1. Docker runtime

개인 로컬 개발 환경을 사용하려면 Docker Compose를 실행할 수 있는 Docker runtime이 필요하다. macOS에서는 Docker Desktop을 가장 단순한 기본값으로 둔다.

```bash
brew install --cask docker
```

설치 후 Docker Desktop을 한 번 실행하고, 터미널에서 확인한다.

```bash
docker --version
docker compose version
```

Docker Desktop 대신 Colima, Rancher Desktop 같은 대안을 사용해도 된다. 이 경우에도 `docker compose version`이 동작해야 한다.

## 2. VMware Workstation / Fusion

Windows는 VMware Workstation, macOS는 VMware Fusion을 설치하고 한 번 실행해 둔다. Vagrant가 VM을 만들 때 VMware backend를 사용한다.

확인:

```bash
ls /Applications | grep -i "VMware Fusion"
```

## 3. Homebrew

Vagrant, Ansible 같은 CLI 도구 설치에 사용한다.

설치 여부 확인:

```bash
brew --version
```

Homebrew가 없다면 먼저 설치한다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 4. Vagrant

Vagrant는 로컬 VM을 코드로 만들고 삭제하는 도구다.

```bash
brew install --cask vagrant
```

확인:

```bash
vagrant --version
```

## 5. Vagrant VMware provider

Vagrant가 VMware를 제어하려면 VMware provider plugin과 VMware Utility가 필요하다.

VMware Utility:

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

VMware Utility cask 설치가 실패하면 HashiCorp의 Vagrant VMware Utility 다운로드 페이지에서 macOS용 패키지를 직접 설치한다. 설치 후 `make check-tools`로 다시 확인한다.

HashiCorp tap을 사용하는 대안도 있다.

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/hashicorp-vagrant
```

## 6. Ansible

Ansible은 생성된 VM에 SSH로 접속해서 서버 초기 설정을 자동 수행한다.

```bash
brew install ansible
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
make check-local-dev-tools
make check-tools
```
