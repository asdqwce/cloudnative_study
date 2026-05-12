# VM Spec

공용 DEV 클러스터 구성을 로컬에서 검증할 때 생성되는 VM 정보를 정리한다.

## 생성되는 VM

로컬 VM은 AWS VPC subnet 감각을 유지하기 위해 `10.10.10.0/24` 대역을 사용한다.

| VM | IP | 역할 |
|---|---|---|
| `control-plane-1` | `10.10.10.10` | 이후 `kubeadm init`을 실행할 control-plane 후보 |
| `worker-1` | `10.10.10.11` | 이후 `kubeadm join`으로 붙일 worker 후보 |
| `worker-2` | `10.10.10.12` | 이후 `kubeadm join`으로 붙일 worker 후보 |

## 스펙 설정

VM의 CPU, 메모리, 디스크 기본값은 `.env.example`에 있다. 실제 실행 전에는 `.env`로 복사한 뒤 필요에 맞게 조정한다.

| 설정 | 기본값 | 설명 |
|---|---:|---|
| `CONTROL_PLANE_CPUS` | `4` | control-plane VM vCPU 수 |
| `CONTROL_PLANE_MEMORY_MB` | `4096` | control-plane VM 메모리 |
| `CONTROL_PLANE_DISK_SIZE` | `30GB` | control-plane VM root disk 크기 |
| `WORKER_CPUS` | `4` | worker VM vCPU 수 |
| `WORKER_MEMORY_MB` | `4096` | worker VM 메모리 |
| `WORKER_DISK_SIZE` | `30GB` | worker VM root disk 크기 |

Vagrantfile에서는 이 값들을 읽어 VMware VM의 `numvcpus`, `memsize`, primary disk 설정으로 반영한다. 이미 `.env`를 만든 뒤 스펙 설정을 추가했다면, `.env.example`의 `CONTROL_PLANE_*`, `WORKER_*` 값을 `.env`에도 추가해야 한다.

## 디스크 사용 위치

디스크 설정은 현재 VM의 primary disk 크기를 의미한다. 게스트 Linux 안에서는 대부분 root filesystem(`/`)으로 쓰이고, Kubernetes 관련 데이터도 기본적으로 이 root disk 안에 저장된다.

| 경로 | 디스크 사용 성격 |
|---|---|
| `/` | OS, 패키지, 설정 파일이 저장되는 root filesystem |
| `/var/lib/containerd` | 컨테이너 이미지와 layer 저장 위치로, 실제 작업 공간 성격이 강함 |
| `/var/lib/kubelet` | Pod, volume mount, kubelet 상태 저장 위치로, Kubernetes 실행 중 계속 사용됨 |
| `/var/log` | systemd, kubelet, container runtime 로그 |

호스트 macOS에서는 Vagrant가 VMware VM 파일을 `providers/local-vagrant/.vagrant/` 아래에 관리한다. 실제 VMDK 파일은 VM별 하위 디렉터리 안에 생성된다.

현재는 root disk 하나만 쓰므로 별도의 용량 비율 설정은 없다. `/var/lib/containerd`, `/var/lib/kubelet`, `/var/log`가 모두 같은 root disk를 공유한다. 나중에 컨테이너 이미지와 Pod 데이터를 분리하고 싶다면 secondary disk를 추가하고 Ansible에서 `/var/lib/containerd` 또는 `/var/lib/kubelet`에 mount하는 방식으로 확장한다.

실습 환경처럼 `/home`을 작게 두고 `/var`를 크게 두는 구성이 Kubernetes에는 더 자연스럽다. 일반 사용자 홈 디렉터리는 SSH 접속과 설정 파일 정도만 사용하므로 작아도 되지만, containerd와 kubelet은 `/var` 아래에 이미지, Pod, volume 데이터를 계속 쌓는다.

VMware disk 설정을 바꾼 뒤에는 VM을 끄고 다시 올려야 변경이 안정적으로 적용된다.
