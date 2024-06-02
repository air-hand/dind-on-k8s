all: setup

setup: clean setup-cluster build-dind setup-deployment

setup-cluster:
	@echo "Setting up Kind cluster"
	docker build -t kindest-node:custom-v1.30.0 -f Dockerfile.kind .
	kind create cluster --config=./kind.yml
	helm upgrade --install metrics-server metrics-server/metrics-server -f metrics-server-values.yml -n kube-system
#	kubectl apply -f https://raw.githubusercontent.com/squat/generic-device-plugin/main/manifests/generic-device-plugin.yaml

build-dind:
	docker build -t my-dind:latest -f Dockerfile .
	kind load docker-image my-dind:latest --name $$(yq -r '.name' ./kind.yml)

setup-deployment:
	kubectl apply -f generic-device-plugin-custom.yaml
	kubectl delete -f dind-deployment.yml || true	
	kubectl apply -f dind-deployment.yml

clean:
	kind delete clusters $$(yq -r '.name' ./kind.yml) || true

analysys:
	@echo "Analysing cgroups"
	sudo systemd-cgls --full --all > system-cgls.log
	sudo systemd-cgls memory --full --all > system-cgls-memory.log
	kubectl describe pod -n default > pod-describe.log
	docker exec -it dind-cluster-worker sh -c 'ctr -n k8s.io containers ls'

login:
	kubectl exec -it deploy/dind-deployment -c dind -- /bin/sh

logs:
	kubectl logs -f --tail=1000 -l app=dind -c dind

expand-image-fs:
	docker build -o tmp/ .

container-ls:
	@docker exec -it dind-cluster-worker sh -c 'ctr -n k8s.io containers ls'

container-info: CONTAINER_ID ?= 
container-info:
	@docker exec -it dind-cluster-worker sh -c 'ctr -n k8s.io containers info $(CONTAINER_ID)'

run-docker:
	kubectl exec -it deploy/dind-deployment -c shell -- docker run -it --rm ubuntu:jammy /bin/bash
