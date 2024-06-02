all: setup

setup: clean setup-cluster build-dind setup-deployment

setup-cluster:
	@echo "Setting up Kind cluster"
	kind create cluster --config=./kind.yml
	helm upgrade --install metrics-server metrics-server/metrics-server -f metrics-server-values.yml -n kube-system

build-dind:
	docker build -t my-dind:latest -f Dockerfile .
	kind load docker-image my-dind:latest --name $$(yq -r '.name' ./kind.yml)

setup-deployment:
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
	kubectl exec -it -l app=dind -c dind -- /bin/sh

logs:
	kubectl logs -f --tail=1000 -l app=dind -c dind

expand-image-fs:
	docker build -o tmp/ .
