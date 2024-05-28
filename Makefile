########################################################################################################################
#
# PROJECT - Makefile for your project
#
########################################################################################################################

########################################################################################################################
# Load env file
########################################################################################################################
ifneq (,$(wildcard ./.env))
	include .env
	export
#	ENV_FILE_PARAM = --env-file .env
endif

########################################################################################################################
# Help command
########################################################################################################################
.PHONY: help
help:
	@echo ""
	@echo "Available commands:"
	@echo "------------------------------------------------------------------"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

########################################################################################################################
# Summary
# 1. K3s commands (install, uninstall)
# 2. Namespace and Pod commands (start, stop, restart, logs, deploy)
# 3. Database commands (list, exec, replace)
# 4. Pod management commands (list, shell)
########################################################################################################################

########################################################################################################################
# 1. K3s commands
########################################################################################################################

install-k3s: ## Install k3s
	./scripts/install_k3s.sh

uninstall-k3s: ## Uninstall k3s
	/usr/local/bin/k3s-uninstall.sh

########################################################################################################################
# 2. Namespace and Pod commands
########################################################################################################################

check_namespace: ## Check if namespace is specified (usage: make <rule> NS="namespace")
	@if [ -z "$(NS)" ]; then \
		echo "Error: you must specify a namespace as below:"; \
		echo "make <rule> NS=\"namespace\""; \
		exit 1; \
	fi
	@./scripts/check_namespace_exists.sh ${NS}

check_pod: ## Check if pod is specified (usage: make <rule> NS="namespace" POD="pod")
	@if [ -z "$(POD)" ]; then \
		echo "Error: you must specify a pod as below:"; \
		echo "make <rule> NS=\"namespace\" POD=\"pod\""; \
		exit 1; \
	fi

start: check_namespace ## Start an application or a pod (usage: make start NS="namespace" POD="pod")
	@./scripts/start.sh ${NS} ${POD}

stop: check_namespace ## Stop an application or a pod (usage: make stop NS="namespace" POD="pod")
	@./scripts/stop.sh ${NS} ${POD}

restart: check_namespace ## Restart an application or a pod (usage: make restart NS="namespace" POD="pod")
	@./scripts/restart.sh ${NS} ${POD}

logs: check_namespace check_pod ## Display logs of a pod (usage: make logs NS="namespace" POD="pod")
	@./scripts/logs.sh ${NS} ${POD}

deploy: ## Deploy an application or a namespace (usage: make deploy NS="namespace" [POD="pod"])
	@echo "Starting deploy..."
	@if [ -z "$(NS)" ]; then \
        ./scripts/display_namespaces_and_pods.sh; \
		echo "make deploy NS=\"namespace\"" POD=\"pod_name\"; \
    elif [ -n "$(POD)" ]; then \
		./scripts/check_namespace_exists.sh ${NS}; \
		if [ $$? -eq 0 ]; then \
			./scripts/deploy.sh "$(NS)" "$(POD)"; \
			echo "Deploy completed."; \
		fi \
    else \
		./scripts/check_namespace_exists.sh ${NS}; \
		if [ $$? -eq 0 ]; then \
			./scripts/deploy_namespace.sh "$(NS)"; \
			echo "Deploy completed."; \
		fi \
    fi


re: delete all ## Delete and rebuild all

########################################################################################################################
# 3. Database commands
########################################################################################################################

list_databases: ## List all databases (usage: make list_databases)
	@kubectl exec -it postgres-0 -- psql -U postgres -d postgres -c '\l'

exec_psql: ## Execute psql command (usage: make exec_psql DB_NAME="database_name")
	@if [ -z "$(DB_NAME)" ]; then \
		echo "Error: you must specify a database name using DB_NAME=\"database_name\""; \
		exit 1; \
	fi
	@kubectl exec -it postgres-0 -- psql -U postgres -d ${DB_NAME}

replace_database: ## Replace a database with a dump file or from another DB (usage: make replace_database DB_NAME="database_name" [DB_FROM="source_database_name"] [FILE="path_to_sql_file"])
	@if [ -z "$(DB_NAME)" ]; then \
		echo "Error: you must specify a database name using DB_NAME=\"database_name\""; \
		exit 1; \
	fi
	@if [ -z "$(FILE)" ] && [ -z "$(DB_FROM)" ]; then \
		echo "Error: you must specify either a file path using FILE=\"path_to_sql_file\" or a source database using DB_FROM=\"source_database_name\""; \
		exit 1; \
	fi
	@if [ -n "$(FILE)" ] && [ -n "$(DB_FROM)" ]; then \
		echo "Error: specify only one of FILE or DB_FROM, not both"; \
		exit 1; \
	fi
	@if [ -n "$(DB_FROM)" ]; then \
		echo "Creating dump from database $(DB_FROM)"; \
		kubectl exec postgres-0 -- pg_dump -U postgres $(DB_FROM) --no-owner --no-acl > local_backup.sql; \
		kubectl cp local_backup.sql postgres-0:/tmp/dump_db.sql; \
		rm local_backup.sql; \
	else \
		echo "Using existing SQL file $(FILE)"; \
		kubectl cp $(FILE) postgres-0:/tmp/dump_db.sql; \
	fi
	@kubectl exec postgres-0 -- psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS $(DB_NAME);" || true
	@kubectl exec postgres-0 -- psql -U postgres -d postgres -c "CREATE DATABASE $(DB_NAME);"
	@kubectl exec postgres-0 -- psql -U postgres -d $(DB_NAME) -f /tmp/dump_db.sql
	@kubectl exec postgres-0 -- rm /tmp/dump_db.sql
	@echo "Database replacement complete."


########################################################################################################################
# 4. Pod management commands
########################################################################################################################

sh_pod: ## Access shell of a pod (usage: make sh_pod POD="pod_name" [NS="namespace"])
	@if [ -z "$(POD)" ]; then \
		echo "Error: you must specify a pod name using POD=\"pod_name\""; \
		exit 1; \
	fi
	@if [ -z "$(NS)" ]; then \
		kubectl exec -it $(POD) -- /bin/sh; \
	else \
		kubectl exec -it $(POD) -n $(NS) -- /bin/sh; \
	fi

pod_list: ## List all pods in a namespace (usage: make pod_list [NS="namespace"])
	@scripts/display_namespaces_and_pods.sh

pod_list_old:
	@if [ -z "$(NS)" ]; then \
		echo "Listing pods in all namespaces:"; \
		kubectl get pods --all-namespaces; \
	else \
		echo "Listing pods in namespace $(NS):"; \
		kubectl get pods -n $(NS); \
	fi

########################################################################################################################
# Aliases
########################################################################################################################
all: ## Display all available commands
	@make help

