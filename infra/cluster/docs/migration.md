# Migration

로컬 검증 환경과 클라우드 DEV 환경의 경계는 VM 생성 계층이다. 서버 안을 설정하는 작업은 `provision/ansible`이 담당한다.

## 현재 구조

```text
로컬:
Vagrant + VMware Fusion -> provision/ansible/inventories/local-vagrant/<topology>.ini -> Ansible

클라우드:
Terraform + VM -> provision/ansible/inventories/aws/<env>.ini -> Ansible
```

Provider는 VM을 만들고 Ansible inventory를 제공한다. Ansible playbook은 provider와 무관하게 같은 서버 초기 설정을 수행한다.

## 로컬에서 클라우드로 옮길 때 바뀌는 것

| 영역 | 로컬 VMware | 클라우드 |
|---|---|---|
| VM 생성 | Vagrantfile | Terraform |
| OS 이미지 | Vagrant Box | AMI, image, custom image |
| 네트워크 | VMware private network | VPC/subnet/security group |
| 접속 정보 | static inventory | Terraform output 기반 inventory |
| 서버 초기 설정 | Ansible | Ansible |

## 유지되는 것

| 영역 | 유지 이유 |
|---|---|
| Ansible playbook | 부팅된 Linux 서버를 Kubernetes 노드 후보로 만드는 작업은 provider와 독립적 |
| 서버 유틸리티 | 운영/디버깅 도구는 로컬 VM과 클라우드 VM 모두 필요 |
| kubeadm 준비 과정 | containerd, kubelet, kubeadm, kubectl 설치 흐름은 동일 |

개인 로컬 개발 환경은 이 경로와 독립적이다. 팀원은 Docker Compose만으로 의존성을 띄우고, 플랫폼 담당자는 Vagrant/Ansible/kubeadm으로 공용 DEV 클러스터 구성을 검증한다.
