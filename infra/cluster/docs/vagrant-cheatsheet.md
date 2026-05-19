# Vagrant Command Cheatsheet

이 문서는 `providers/local-vagrant/Vagrantfile`로 관리되는 VMware Fusion VM을 다룰 때 자주 쓰는 명령을 정리한다.

## 기준 위치

`vagrant status`, `vagrant ssh` 같은 명령은 `Vagrantfile`이 있는 디렉터리에서 실행한다.

```bash
cd "/path/to/cloudnative_study/infra/cluster/providers/local-vagrant"
```

`infra/cluster` 디렉터리에서는 Makefile target을 사용할 수 있다.

```bash
cd "/path/to/cloudnative_study/infra/cluster"
```

## 상태 확인

| 목적 | 명령 |
|---|---|
| 현재 Vagrantfile의 VM 상태 확인 | `vagrant status` |
| 특정 VM 상태 확인 | `vagrant status control-plane-1` |
| Mac 전체 Vagrant VM 목록 확인 | `vagrant global-status --prune` |
| SSH 접속 정보 확인 | `vagrant ssh-config` |
| 특정 VM SSH 접속 정보 확인 | `vagrant ssh-config control-plane-1` |

Makefile을 사용할 때는 다음 명령으로 감싼다.

```bash
make local-vms-status
```

## VM 생성과 시작

| 목적 | 명령 |
|---|---|
| 전체 VM 생성/시작 | `vagrant up --provider=vmware_desktop` |
| 특정 VM만 생성/시작 | `vagrant up control-plane-1 --provider=vmware_desktop` |
| 꺼진 VM 다시 시작 | `vagrant up` |
| provision 다시 실행하며 시작 | `vagrant up --provision` |

Makefile을 사용할 때는 다음 명령을 쓴다.

```bash
make local-vms-up
```

## SSH 접속

| 목적 | 명령 |
|---|---|
| control-plane 접속 | `vagrant ssh control-plane-1` |
| worker-1 접속 | `vagrant ssh worker-1` |
| worker-2 접속 | `vagrant ssh worker-2` |
| global-status의 ID로 접속 | `vagrant ssh <id>` |

예시:

```bash
vagrant ssh control-plane-1
```

## 중지와 재시작

| 목적 | 명령 |
|---|---|
| 전체 VM 정상 종료 | `vagrant halt` |
| 특정 VM 정상 종료 | `vagrant halt worker-1` |
| 전체 VM 재시작 | `vagrant reload` |
| 특정 VM 재시작 | `vagrant reload worker-1` |
| provision 다시 실행하며 재시작 | `vagrant reload --provision` |
| 일시 정지 | `vagrant suspend` |
| 일시 정지 해제 | `vagrant resume` |

Makefile을 사용할 때는 다음 명령을 쓴다.

```bash
make local-vms-halt
```

## 삭제

`destroy`는 VM을 삭제한다. 디스크도 함께 사라지므로 실험 환경을 처음부터 다시 만들 때만 사용한다.

| 목적 | 명령 |
|---|---|
| 전체 VM 삭제 | `vagrant destroy -f` |
| 특정 VM 삭제 | `vagrant destroy -f worker-2` |

Makefile을 사용할 때는 다음 명령을 쓴다.

```bash
make local-vms-destroy
```

기존 `make local-vms-down`은 호환을 위해 남아 있지만, 실제 동작은 삭제이므로 새 명령인 `make local-vms-destroy`를 사용한다.

## 처음부터 다시 구성

VM을 삭제하고 inventory를 정리한 뒤 전체 bootstrap을 다시 실행한다.

```bash
make local-vms-reset
```

수동으로 같은 작업을 하려면:

```bash
make local-vms-destroy
make clean
make local-bootstrap
```

## Provision

Vagrantfile의 shell provisioner만 다시 실행할 때 사용한다. 현재 프로젝트의 Kubernetes 서버 초기 설정은 Ansible/Makefile 쪽에서 따로 실행한다.

| 목적 | 명령 |
|---|---|
| 전체 Vagrant provision 실행 | `vagrant provision` |
| 특정 VM provision 실행 | `vagrant provision control-plane-1` |

서버와 Kubernetes 클러스터 초기 설정까지 포함한 프로젝트 흐름은 다음 순서다.

```bash
make local-vms-up
make local-inventory
make ansible-ping
make servers-bootstrap
make servers-verify
make cluster-bootstrap
make cluster-verify
```

한 번에 실행하려면:

```bash
make local-bootstrap
```

## VMware Fusion에서 열기

Vagrant가 만든 VM은 Fusion Library에 자동 등록되지 않을 수 있다. `.vmx` 파일을 직접 열면 Fusion에서 콘솔을 볼 수 있다.

```bash
find .vagrant/machines -name "*.vmx"
open -a "VMware Fusion" "<vmx-file-path>"
```

Finder에서 위치를 열 때는:

```bash
open -R "<vmx-file-path>"
```

## 문제 상황별 빠른 확인

| 상황 | 확인 명령 |
|---|---|
| `Vagrantfile`을 못 찾는다는 오류 | `pwd`로 현재 위치 확인 후 `providers/local-vagrant`로 이동 |
| VM은 있는데 현재 폴더에서 안 보임 | `vagrant global-status --prune` |
| SSH 접속이 안 됨 | `vagrant status` 후 `vagrant ssh-config <vm-name>` 확인 |
| Fusion UI에 VM이 안 보임 | `find .vagrant/machines -name "*.vmx"`로 직접 열기 |
| 처음부터 다시 만들기 | `make local-vms-reset` |
