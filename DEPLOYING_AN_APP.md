# Deploying an Application to the Stack

So you want to deploy an application to the Polarstomps Kubernetes cluster, eh? Here is the guide to do it.

If you need an example application then use:

The Kubernetes manifests for the Polarstomps webapp: [polarstomps-argo-gcp]()
And the infrastructure that goes alongside it: [polarstomps webapp tf module]()

All applications should be deployed and managed by [ArgoCD](https://argo-cd.readthedocs.io/en/stable/). It's a gitops based deploy tool that will pull Kubernetes manifests from git and then try its best to sync the declared state to a Kubernetes cluster.

## How do I get my application onto the cluster?

To start, create a repo named `<app_name>-argo-gcp`. Then, inside of it, define an `<application.yml>`.

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app_name>
spec:
  project: default
  source:
    repoURL: https://github.com/howdoicomputer/polarstomps-argo-gcp
    targetRevision: prod
    path: <app_name>
  destination:
    server: https://kubernetes.default.svc
    namespace: <app_name>
  syncPolicy:
    syncOptions:
      - PruneLast=true
      - CreateNamespace=false
```


## How do I expose my application to the Internet?

## How do I generate an SSL certificate for my applications domain name?

## How do I provision a database and access it securely?

## How do I enable logging and metrics for my application?

## How do I enable healthchecks for my application?

## How do I support different environments for my application?

## How do I do rolling deployments for my application?
