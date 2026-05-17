# Local Vagrant Provider

VMware Workstation / Fusion 위에 Kubernetes 노드용 Ubuntu VM 3대를 생성하는 Vagrant provider입니다.

이 provider는 VM 생성까지만 담당합니다. VM 내부에 `containerd`, `kubeadm`, `kubelet`, `kubectl`을 설치하고 Kubernetes 클러스터를 구성하는 작업은 `infra/cluster/provision/ansible`이 담당합니다.

## VM 구성

| VM | IP | 역할 | 기본 CPU | 기본 Memory |
|---|---|---|---:|---:|
| `control-plane-1` | `10.10.10.10` | Kubernetes control-plane | `2` | `3072MB` |
| `worker-1` | `10.10.10.11` | 애플리케이션 Pod 실행 노드 | `2` | `2048MB` |
| `worker-2` | `10.10.10.12` | 애플리케이션 Pod 실행 노드 | `2` | `2048MB` |

기본값은 `infra/cluster/.env.example`에서 관리합니다. 실행 전에 `.env.example`을 `.env`로 복사한 뒤 필요하면 CPU, 메모리, Vagrant box 값을 조정합니다.

## 사전 준비

Windows:

- VMware Workstation
- Vagrant
- Vagrant VMware Utility
- `vagrant-vmware-desktop` plugin

macOS:

- VMware Fusion
- Vagrant
- Vagrant VMware Utility
- `vagrant-vmware-desktop` plugin

플러그인 설치:

```powershell
vagrant plugin install vagrant-vmware-desktop
```

설치 확인:

```powershell
vagrant --version
vagrant plugin list
```

`vagrant plugin list` 결과에 `vagrant-vmware-desktop`이 보여야 합니다.

## Windows / WSL 실행 기준

Windows 사용자는 역할을 나눠 실행합니다.

| 작업 | 실행 위치 |
|---|---|
| Vagrant VM 생성, 상태 확인, 삭제 | Windows PowerShell |
| Ansible 실행 | WSL |

프로젝트는 Windows 경로에 두고 WSL에서는 `/mnt/d/...` 경로로 같은 폴더에 접근합니다.

```text
Windows: D:\develop\cloudnative_study\infra\cluster
WSL:     /mnt/d/develop/cloudnative_study/infra/cluster
```

## 환경 파일

Windows PowerShell:

```powershell
cd D:\develop\cloudnative_study\infra\cluster
copy .env.example .env
```

WSL 또는 macOS:

```bash
cd infra/cluster
cp .env.example .env
```

Apple Silicon Mac은 ARM64 Ubuntu Vagrant box가 필요할 수 있습니다. 이 경우 `.env`의 `LOCAL_VAGRANT_BOX` 값을 해당 환경에 맞게 변경합니다.

## VM 생성

Windows PowerShell 또는 macOS Terminal에서 실행합니다.

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant up --provider=vmware_desktop
```

상태 확인:

```powershell
vagrant status
```

정상 상태:

```text
control-plane-1   running
worker-1          running
worker-2          running
```

## SSH 접속

Vagrant SSH는 Vagrant가 설치된 환경에서 실행합니다.

Windows PowerShell:

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant ssh control-plane-1
```

WSL에는 Vagrant를 설치하지 않아도 됩니다. WSL에서는 Ansible로 VM에 접속합니다.

## Ansible SSH key 주의사항

Windows 경로를 WSL에서 보면 private key 권한이 `0777`처럼 보일 수 있습니다. 이 경우 SSH가 다음 오류로 key 사용을 거부합니다.
wsl이 아닌 로컬 환경의 경우 오류 발생 가능성이 적으니 아래는 무시하셔도 됩니다.

```text
WARNING: UNPROTECTED PRIVATE KEY FILE
Permissions 0777 ... are too open.
```

해결 방법은 Vagrant가 생성한 private key를 WSL 홈 디렉터리로 복사하고 권한을 제한하는 것입니다.

```bash
mkdir -p ~/.ssh/cloudnative-vagrant
chmod 700 ~/.ssh ~/.ssh/cloudnative-vagrant

cp providers/local-vagrant/.vagrant/machines/control-plane-1/vmware_desktop/private_key ~/.ssh/cloudnative-vagrant/control-plane-1
cp providers/local-vagrant/.vagrant/machines/worker-1/vmware_desktop/private_key ~/.ssh/cloudnative-vagrant/worker-1
cp providers/local-vagrant/.vagrant/machines/worker-2/vmware_desktop/private_key ~/.ssh/cloudnative-vagrant/worker-2

chmod 600 ~/.ssh/cloudnative-vagrant/control-plane-1
chmod 600 ~/.ssh/cloudnative-vagrant/worker-1
chmod 600 ~/.ssh/cloudnative-vagrant/worker-2
```

그 다음 `infra/cluster/provision/ansible/inventory.ini`의 `ansible_ssh_private_key_file` 값을 WSL 홈 경로로 맞춥니다.

```ini
ansible_ssh_private_key_file=~/.ssh/cloudnative-vagrant/control-plane-1
```

비밀번호와 private key 파일 내용은 Git에 커밋하지 않습니다.

## Ansible 접속 확인

WSL 또는 macOS Terminal에서 실행합니다.

```bash
cd /mnt/d/develop/cloudnative_study/infra/cluster
ansible -i provision/ansible/inventory.ini all -m ping
```

성공 예시:

```text
control-plane-1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Kubernetes 서버 설정

Ansible 접속이 성공하면 서버 기본 설정을 적용합니다.

```bash
make servers-bootstrap
make servers-verify
```

이 단계에서 수행하는 작업:

- 기본 패키지 설치
- `containerd` 설치 및 systemd cgroup 설정
- swap 비활성화
- Kubernetes kernel module 설정
- sysctl 설정
- `kubeadm`, `kubelet`, `kubectl` 설치

## Kubernetes 클러스터 구성

```bash
make cluster-bootstrap
make cluster-verify
```

성공 기준:

```text
control-plane-1   Ready
worker-1          Ready
worker-2          Ready
CoreDNS           Running
Calico            Running
```

## VM 삭제

Windows PowerShell 또는 macOS Terminal:

```powershell
cd D:\develop\cloudnative_study\infra\cluster\providers\local-vagrant
vagrant destroy -f
```

이 명령은 VM과 디스크를 삭제합니다.
