SHELL := /bin/sh

.DEFAULT_GOAL := help

ROOT_DIR ?= ..
TERRAFORM ?= $(ROOT_DIR)/.tools/terraform
TF_ARGS ?=

TERRAFORM_COMMANDS := init validate plan apply destroy output show fmt version providers workspace state import taint untaint refresh console graph force-unlock
DEFAULT_AWS_INVENTORY ?= $(ROOT_DIR)/.tools/ansible/aws.ini
AWS_INVENTORY ?= $(DEFAULT_AWS_INVENTORY)
AWS_GENERATE_INVENTORY ?= $(if $(filter $(DEFAULT_AWS_INVENTORY),$(AWS_INVENTORY)),true,false)
AWS_ANSIBLE_PLAYBOOK_DIR ?= $(ROOT_DIR)/infra/cluster/provision/ansible/playbooks
AWS_ANSIBLE_GENERATED_INVENTORY_DIR ?= $(dir $(AWS_INVENTORY))
AWS_ANSIBLE_SSH_USER ?= ubuntu
AWS_ANSIBLE_SSH_PRIVATE_KEY_FILE ?= $(shell public_key_path="$$(sed -n 's/^[[:space:]]*k8s_public_key_path[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' terraform.tfvars 2>/dev/null | tail -n 1)"; if [ -n "$$public_key_path" ]; then printf '%s' "$${public_key_path%.pub}"; else printf '%s' ~/.ssh/k8s-key; fi)
ANSIBLE_PLAYBOOK ?= ansible-playbook
ANSIBLE_FLAGS ?=
AWS_ANSIBLE_FLAGS ?= -e '{"local_registry_enabled": false}'

.PHONY: help aws-bootstrap aws-ansible-syntax-check \
	_aws-inventory _aws-servers-bootstrap _aws-cluster-bootstrap _aws-ecr-credential-provider-bootstrap _aws-helm-bootstrap _aws-argocd-bootstrap \
	$(TERRAFORM_COMMANDS)

help:
	@printf '%s\n' 'Terraform commands'
	@printf '  %-28s %s\n' 'make init' 'Terraform 작업 디렉터리를 초기화합니다.'
	@printf '  %-28s %s\n' 'make validate' 'Terraform 구성을 검증합니다.'
	@printf '  %-28s %s\n' 'make plan' 'Terraform 변경 계획을 확인합니다.'
	@printf '  %-28s %s\n' 'make apply' 'Terraform 변경을 적용합니다.'
	@printf '  %-28s %s\n' 'make output' 'Terraform output을 조회합니다.'
	@printf '  %-28s %s\n' 'make aws-bootstrap' 'Terraform output 기반 AWS inventory로 클러스터 bootstrap을 실행합니다.'
	@printf '  %-28s %s\n' 'TF_ARGS="..." make plan' '추가 Terraform 인자를 전달합니다.'

$(TERRAFORM_COMMANDS):
	@if [ ! -x "$(TERRAFORM)" ]; then \
		printf '%s\n' 'Terraform not found. Run make install first.' >&2; \
		exit 1; \
	fi
	@$(TERRAFORM) $@ $(TF_ARGS)

_aws-inventory:
	@set -e; \
	if [ ! -x "$(TERRAFORM)" ]; then \
		printf '%s\n' 'Terraform not found. Run make install first.' >&2; \
		exit 1; \
	fi; \
	master_ip="$$( $(TERRAFORM) output -raw master_public_ip )"; \
	worker_ips="$$( $(TERRAFORM) output -json worker_public_ips | sed 's/[][]//g; s/"//g; s/,/ /g' )"; \
	if [ -z "$$master_ip" ] || [ -z "$$worker_ips" ]; then \
		printf '%s\n' 'Terraform outputs master_public_ip and worker_public_ips are required. Run make terraform apply first.' >&2; \
		exit 1; \
	fi; \
	private_key_file="$(AWS_ANSIBLE_SSH_PRIVATE_KEY_FILE)"; \
	case "$$private_key_file" in "~/"*) private_key_check_path="$$HOME/$${private_key_file#\~/}" ;; *) private_key_check_path="$$private_key_file" ;; esac; \
	if [ ! -f "$$private_key_check_path" ]; then \
		printf 'SSH private key not found: %s\n' "$$private_key_file" >&2; \
		printf '%s\n' 'Set AWS_ANSIBLE_SSH_PRIVATE_KEY_FILE=/path/to/private-key if needed.' >&2; \
		exit 1; \
	fi; \
	mkdir -p "$(AWS_ANSIBLE_GENERATED_INVENTORY_DIR)"; \
	{ \
		printf '%s\n' '# Generated from Terraform outputs. Do not edit.'; \
		printf '%s\n\n' '# Override AWS_INVENTORY to use a different inventory file.'; \
		printf '%s\n' '[control_plane]'; \
		printf 'control-plane-1 ansible_host=%s ansible_user=%s ansible_port=22 ansible_ssh_private_key_file=%s\n\n' "$$master_ip" "$(AWS_ANSIBLE_SSH_USER)" "$$private_key_file"; \
		printf '%s\n' '[workers]'; \
		i=1; \
		for worker_ip in $$worker_ips; do \
			printf 'worker-%s ansible_host=%s ansible_user=%s ansible_port=22 ansible_ssh_private_key_file=%s\n' "$$i" "$$worker_ip" "$(AWS_ANSIBLE_SSH_USER)" "$$private_key_file"; \
			i=$$((i + 1)); \
		done; \
		printf '\n%s\n\n' '[platform_nodes]'; \
		printf '%s\n\n' '[app_nodes]'; \
		printf '%s\n\n' '[postgres_nodes]'; \
		printf '%s\n\n' '[kafka_nodes]'; \
		printf '%s\n%s\n\n' '[kube_control_plane:children]' 'control_plane'; \
		printf '%s\n%s\n\n' '[kube_workers:children]' 'workers'; \
		printf '%s\n%s\n%s\n\n' '[k8s_cluster:children]' 'control_plane' 'workers'; \
		printf '%s\n' '[k8s_cluster:vars]'; \
		printf '%s\n' 'ansible_python_interpreter=/usr/bin/python3'; \
		printf '%s\n' "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"; \
	} > "$(AWS_INVENTORY)"; \
	printf 'Generated %s from Terraform outputs.\n' "$(AWS_INVENTORY)"

_aws-servers-bootstrap:
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-servers.yml

_aws-cluster-bootstrap:
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-cluster.yml
	$(MAKE) _aws-ecr-credential-provider-bootstrap

_aws-ecr-credential-provider-bootstrap:
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-aws-ecr-credential-provider.yml

_aws-helm-bootstrap:
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-helm.yml

_aws-argocd-bootstrap:
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-argocd.yml

aws-bootstrap:
	@if [ "$(AWS_GENERATE_INVENTORY)" = "true" ]; then \
		$(MAKE) _aws-inventory; \
	fi
	$(MAKE) _aws-servers-bootstrap
	$(MAKE) _aws-cluster-bootstrap
	$(MAKE) _aws-helm-bootstrap
	$(MAKE) _aws-argocd-bootstrap

aws-ansible-syntax-check:
	@if [ "$(AWS_GENERATE_INVENTORY)" = "true" ]; then \
		$(MAKE) _aws-inventory; \
	fi
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) --syntax-check $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-servers.yml
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) --syntax-check $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-cluster.yml
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) --syntax-check $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-aws-ecr-credential-provider.yml
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) --syntax-check $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-helm.yml
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_FLAGS) $(AWS_ANSIBLE_FLAGS) -i $(AWS_INVENTORY) --syntax-check $(AWS_ANSIBLE_PLAYBOOK_DIR)/bootstrap-argocd.yml
