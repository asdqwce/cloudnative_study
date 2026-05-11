# Providers

Provider는 VM을 만드는 계층이다. 서버 안을 설정하는 작업은 `provision/ansible`이 담당한다.

| Provider | 상태 | 역할 |
|---|---|---|
| `local-vagrant` | 구현됨 | VMware Fusion에서 로컬 VM 3대 생성 |
| `aws-terraform` | 예정 | AWS EC2로 control-plane/worker VM 생성 |

마이그레이션 원칙은 단순하다.

```text
Provider가 VM을 만든다.
Provider가 Ansible inventory를 제공한다.
Ansible playbook은 provider와 무관하게 같은 작업을 수행한다.
```
