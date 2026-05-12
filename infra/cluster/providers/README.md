# Providers

Provider는 Kubernetes 노드로 사용할 VM을 생성하는 계층입니다. VM 내부의 패키지 설치, containerd 설정, kubeadm 클러스터 구성은 `provision/ansible`의 playbook이 담당합니다.

## 현재 Provider

| Provider | 상태 | 역할 |
|---|---|---|
| `local-vagrant` | 구현됨 | VMware Workstation / Fusion 위에 로컬 VM 3대를 생성 |

## 책임 분리

```text
providers/
  VM 생성, 네트워크 IP, CPU, 메모리, SSH 접속 기반 제공

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
1. local-vagrant provider가 VM 3대 생성
2. Vagrant가 각 VM의 SSH key 생성
3. Ansible inventory가 VM IP와 SSH key 경로를 사용
4. Ansible이 VM에 Kubernetes 실행 기반 설치
5. kubeadm으로 control-plane과 worker node 구성
```

자세한 실행 방법은 [local-vagrant/README.md](local-vagrant/README.md)를 참고합니다.
