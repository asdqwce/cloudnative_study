# Local Vagrant Provider

VMware Fusion에서 로컬 Kubernetes 실험용 VM 3대를 생성한다.

## 사전 준비

```bash
vagrant plugin install vagrant-vmware-desktop
```

VMware Utility도 필요하다. 설치 후 `make check-tools`로 확인한다.

Apple Silicon Mac에서는 ARM64를 지원하는 Vagrant box가 필요할 수 있다. 기본값은 `.env.example`의 `bento/ubuntu-22.04`이며, 환경에 맞지 않으면 `.env`의 `LOCAL_VAGRANT_BOX`를 바꾼다.

## VM

로컬 VM은 AWS VPC subnet 감각을 유지하기 위해 `10.10.10.0/24` 대역을 사용한다.

| VM | IP | CPU | Memory | Disk |
|---|---|---:|---:|---:|
| `control-plane-1` | `10.10.10.10` | `.env`의 `CONTROL_PLANE_CPUS` 기본 `4` | `.env`의 `CONTROL_PLANE_MEMORY_MB` 기본 `4096` | `.env`의 `CONTROL_PLANE_DISK_SIZE` 기본 `30GB` |
| `worker-1` | `10.10.10.11` | `.env`의 `WORKER_CPUS` 기본 `4` | `.env`의 `WORKER_MEMORY_MB` 기본 `4096` | `.env`의 `WORKER_DISK_SIZE` 기본 `30GB` |
| `worker-2` | `10.10.10.12` | `.env`의 `WORKER_CPUS` 기본 `4` | `.env`의 `WORKER_MEMORY_MB` 기본 `4096` | `.env`의 `WORKER_DISK_SIZE` 기본 `30GB` |
