PROJECT_ID=$(shell gcloud config list project --format=flattened | awk 'FNR == 1 {print $$2}')
CLUSTER_NAME=myfirstcluster
ASIACLUSTER_NAME=asia-cluster
EUCLUSTER_NAME=eu-cluster
USCLUSTER_NAME=us-cluster
FEDNAME=federatedcluster
INGRESSIPNAME=globalapp-ip
GCLOUD_USER=$(shell gcloud config get-value core/account)
ZONE=asia-southeast1-a
ASIAZONE=asia-southeast1-a
EUZONE=europe-west2-a
USZONE=us-central1-a

create-cluster1:
	gcloud container --project "$(PROJECT_ID)" clusters create "$(CLUSTER_NAME)" --zone "$(ZONE)" --machine-type "n1-standard-1" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --network "default" --enable-cloud-logging --enable-cloud-monitoring
	gcloud container clusters get-credentials $(CLUSTER_NAME) --zone $(ZONE) --project $(PROJECT_ID)

create-deployment1:
	kubectl create -f manifests/GlobalGoApp-deployment.yaml

create-loadbalancer1:
	kubectl create -f manifests/GlobalGoApp-loadbalancer.yaml

delete-cluster1:
	gcloud --quiet container clusters delete "$(CLUSTER_NAME)" --zone "$(ZONE)"


create-allclusters:
	gcloud container --project "$(PROJECT_ID)" clusters create "$(ASIACLUSTER_NAME)" --zone "$(ASIAZONE)" --machine-type "n1-standard-1" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/ndev.clouddns.readwrite","https://www.googleapis.com/auth/cloud-platform" --num-nodes "3" --network "default" --enable-cloud-logging --enable-cloud-monitoring
	gcloud container --project "$(PROJECT_ID)" clusters create "$(EUCLUSTER_NAME)" --zone "$(EUZONE)" --machine-type "n1-standard-1" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/ndev.clouddns.readwrite","https://www.googleapis.com/auth/cloud-platform" --num-nodes "3" --network "default" --enable-cloud-logging --enable-cloud-monitoring
	gcloud container --project "$(PROJECT_ID)" clusters create "$(USCLUSTER_NAME)" --zone "$(USZONE)" --machine-type "n1-standard-1" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/ndev.clouddns.readwrite","https://www.googleapis.com/auth/cloud-platform" --num-nodes "3" --network "default" --enable-cloud-logging --enable-cloud-monitoring
	gcloud container clusters get-credentials "$(ASIACLUSTER_NAME)" --zone "$(ASIAZONE)" --project gcpdemoproject
	gcloud container clusters get-credentials "$(EUCLUSTER_NAME)" --zone "$(EUZONE)" --project gcpdemoproject
	gcloud container clusters get-credentials "$(USCLUSTER_NAME)" --zone "$(USZONE)" --project gcpdemoproject
	
prepare-contexts:
	kubectl config set-context $(ASIACLUSTER_NAME) --cluster gke_$(PROJECT_ID)_$(ASIAZONE)_$(ASIACLUSTER_NAME) --user gke_$(PROJECT_ID)_$(ASIAZONE)_$(ASIACLUSTER_NAME)
	kubectl config set-context $(EUCLUSTER_NAME) --cluster gke_$(PROJECT_ID)_$(EUZONE)_$(EUCLUSTER_NAME) --user gke_$(PROJECT_ID)_$(EUZONE)_$(EUCLUSTER_NAME)
	kubectl config set-context $(USCLUSTER_NAME) --cluster gke_$(PROJECT_ID)_$(USZONE)_$(USCLUSTER_NAME) --user gke_$(PROJECT_ID)_$(USZONE)_$(USCLUSTER_NAME)
	kubectl config use-context $(ASIACLUSTER_NAME)
	kubectl config delete-context gke_$(PROJECT_ID)_$(ASIAZONE)_$(ASIACLUSTER_NAME)
	kubectl config delete-context gke_$(PROJECT_ID)_$(EUZONE)_$(EUCLUSTER_NAME)
	kubectl config delete-context gke_$(PROJECT_ID)_$(USZONE)_$(USCLUSTER_NAME)
	kubectl create clusterrolebinding clrbinding --clusterrole=cluster-admin --user=<TODO> #change this to your service account
	kubectl config use-context $(EUCLUSTER_NAME)
	kubectl create clusterrolebinding clrbinding --clusterrole=cluster-admin --user=<TODO> #change this to your service account
	kubectl config use-context $(USCLUSTER_NAME)
	kubectl create clusterrolebinding clrbinding --clusterrole=cluster-admin --user=<TODO> #change this to your service account
	kubectl config use-context $(ASIACLUSTER_NAME)


get-kubefed:
	gsutil cp gs://kubernetes-federation-release/release/v1.9.0-beta.0/federation-client-linux-amd64.tar.gz .
	tar -xzvf federation-client-linux-amd64.tar.gz
	sudo cp federation/client/bin/kubefed /usr/local/bin
	sudo chmod +X /usr/local/bin/kubefed #this isn't necessary, but including just in case.

create-federatedcluster:
	kubefed init $(FEDNAME) --host-cluster-context=$(ASIACLUSTER_NAME) --dns-zone-name="gcpdemo.xyz" --dns-provider="google-clouddns"
	kubefed --context $(FEDNAME) join $(ASIACLUSTER_NAME) --cluster-context=$(ASIACLUSTER_NAME) --host-cluster-context=$(ASIACLUSTER_NAME)
	kubefed --context $(FEDNAME) join $(EUCLUSTER_NAME) --cluster-context=$(EUCLUSTER_NAME) --host-cluster-context=$(ASIACLUSTER_NAME)
	kubefed --context $(FEDNAME) join $(USCLUSTER_NAME) --cluster-context=$(USCLUSTER_NAME) --host-cluster-context=$(ASIACLUSTER_NAME)
	kubectl --context=$(FEDNAME) create ns default
	kubectl --context=$(FEDNAME) get all

create-rolebinding1:
	kubectl create clusterrolebinding clrbinding --clusterrole=cluster-admin --user=<TODO>

create-rolebinding2:
	kubectl create clusterrolebinding clrbinding --clusterrole=cluster-admin --user=admin

create-globalip:
	gcloud compute addresses create globalapp-ip --global

create-deployment2:
	kubectl --context="$(FEDNAME)" create -f manifests/GlobalGoApp-feddeployment.yaml
	kubectl --context="$(FEDNAME)" create -f manifests/GlobalSmallApp-feddeployment.yaml
	kubectl --context="$(FEDNAME)" get pods

create-nodeport2:
	kubectl --context="$(FEDNAME)" create -f manifests/GlobalGoApp-nodeport.yaml
	kubectl --context="$(FEDNAME)" create -f manifests/GlobalSmallApp-nodeport.yaml
	kubectl --context="$(FEDNAME)" get service

create-ingress:
	kubectl --context="$(FEDNAME)" create -f manifests/GlobalApp-Ingress.yaml
	kubectl --context="$(FEDNAME)" describe ingress

create-secret:
	kubectl create secret generic thekey --from-file=<PATH-TO-KEY-FILE>

create-secretdeployment:
	kubectl --context="$(FEDNAME)" delete -f manifests/GlobalSmallApp-deployment.yaml
	kubectl --context="$(FEDNAME)" create -f manifests/GlobalSmallApp-deploymentwithkey.yaml

delete-contexts:
	kubectl config delete-context gke_gcpdemoproject_asia-southeast1-a_asia-cluster
	kubectl config delete-context gke_gcpdemoproject_europe-west2-a_eu-cluster
	kubectl config delete-context gke_gcpdemoproject_us-central1-a_us-cluster

create-testdeployment:

	kubectl --context=$(ASIACLUSTER_NAME) create -f manifests/GlobalGoApp-deployment.yaml
	kubectl --context=$(EUCLUSTER_NAME) create -f manifests/GlobalGoApp-deployment.yaml
	kubectl --context=$(USCLUSTER_NAME) create -f manifests/GlobalGoApp-deployment.yaml
	kubectl --context=$(ASIACLUSTER_NAME) create -f manifests/GlobalSmallApp-deployment.yaml
	kubectl --context=$(EUCLUSTER_NAME) create -f manifests/GlobalSmallApp-deployment.yaml
	kubectl --context=$(USCLUSTER_NAME) create -f manifests/GlobalSmallApp-deployment.yaml
	kubectl --context=$(ASIACLUSTER_NAME) create -f manifests/GlobalGoApp-nodeport.yaml
	kubectl --context=$(EUCLUSTER_NAME) create -f manifests/GlobalGoApp-nodeport.yaml
	kubectl --context=$(USCLUSTER_NAME) create -f manifests/GlobalGoApp-nodeport.yaml
	kubectl --context=$(ASIACLUSTER_NAME) create -f manifests/GlobalSmallApp-nodeport.yaml
	kubectl --context=$(EUCLUSTER_NAME) create -f manifests/GlobalSmallApp-nodeport.yaml
	kubectl --context=$(USCLUSTER_NAME) create -f manifests/GlobalSmallApp-nodeport.yaml
	kubectl --context=$(ASIACLUSTER_NAME) create -f manifests/GlobalApp-Ingress.yaml
	kubectl --context=$(EUCLUSTER_NAME) create -f manifests/GlobalApp-Ingress.yaml
	kubectl --context=$(USCLUSTER_NAME) create -f manifests/GlobalApp-Ingress.yaml

create-testdeployment2:
	kubectl --context=$(ASIACLUSTER_NAME) apply -f manifests/GlobalSmallApp-deployment.yaml
	kubectl --context=$(EUCLUSTER_NAME) apply -f manifests/GlobalSmallApp-deployment.yaml
	kubectl --context=$(USCLUSTER_NAME) apply -f manifests/GlobalSmallApp-deployment.yaml