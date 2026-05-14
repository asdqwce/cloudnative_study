# Providers

Provider는 Kubernetes 노드로 사용할 VM을 생성하는 계층입니다. VM 내부의 패키지 설치, containerd 설정, kubeadm 클러스터 구성은 `provision/ansible`의 playbook이 담당합니다.

## 현재 Provider

| Provider | 상태 | 역할 |
|---|---|---|
| `local-vagrant` | 구현됨 | VMware Workstation / Fusion 위에 선택된 topology의 로컬 VM을 생성 |

## 책임 분리

```text
providers/
  VM 생성 방식, 네트워크, SSH 접속 기반 제공

topologies/
  compact, balanced, role-separated 같은 노드 모양, IP, 역할, 기본 스펙 정의

provision/ansible/
  containerd, kubeadm, kubelet, kubectl 설치
  control-plane 초기화
  worker node join
  Kubernetes 클러스터 검증
```

이 구조를 유지하면 나중에 클라우드 VM으로 옮길 때 provider만 교체하고 Ansible playbook은 최대한 재사용할 수 있습니다.

## 실행 흐름

로컬 VMware 기반 클러스터는 다음 순서로 구성합니다.

```text
1. topologies/<name>/nodes.yml이 노드 목록과 역할 정의
2. local-vagrant provider가 선택된 topology의 VM 생성
3. Vagrant가 각 VM의 SSH key 생성
4. Ansible inventory가 VM IP와 SSH key 경로, node label 값을 사용
5. Ansible이 VM에 Kubernetes 실행 기반 설치
6. kubeadm으로 control-plane과 worker node 구성
```

자세한 실행 방법은 [local-vagrant/README.md](local-vagrant/README.md)를 참고합니다.
