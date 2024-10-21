bootstrap-argo:
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

auth-gke:
	gcloud container clusters get-credentials $(terragrunt output -raw gke_cluster_name) --zone us-west1

auth-gcp:
	gcloud auth login

argocd-login:
	kubectl config set-context --current --namespace argocd
	argocd login --core
	argocd admin initial-password -n argocd

argocd-fwd:
	kubectl port-forward svc/argocd-server -n argocd 8080:443
