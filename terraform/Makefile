SHELL := /bin/sh

.DEFAULT_GOAL := help

TERRAFORM ?= ../.tools/terraform
TF_ARGS ?=

TERRAFORM_COMMANDS := init validate plan apply destroy output show fmt version providers workspace state import taint untaint refresh console graph force-unlock

.PHONY: help $(TERRAFORM_COMMANDS)

help:
	@printf '%s\n' 'Terraform commands'
	@printf '  %-28s %s\n' 'make init' 'Terraform 작업 디렉터리를 초기화합니다.'
	@printf '  %-28s %s\n' 'make validate' 'Terraform 구성을 검증합니다.'
	@printf '  %-28s %s\n' 'make plan' 'Terraform 변경 계획을 확인합니다.'
	@printf '  %-28s %s\n' 'make apply' 'Terraform 변경을 적용합니다.'
	@printf '  %-28s %s\n' 'make output' 'Terraform output을 조회합니다.'
	@printf '  %-28s %s\n' 'TF_ARGS="..." make plan' '추가 Terraform 인자를 전달합니다.'

$(TERRAFORM_COMMANDS):
	@if [ ! -x "$(TERRAFORM)" ]; then \
		printf '%s\n' 'Terraform not found. Run make install first.' >&2; \
		exit 1; \
	fi
	@$(TERRAFORM) $@ $(TF_ARGS)
