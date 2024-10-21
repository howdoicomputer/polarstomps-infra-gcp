# About

This Terraform/Terragrunt repository contains the infrastructure-as-code necessary to build out a very simple, reference GCP architecture with a VPC-per-environment approach with a GKE cluster in each environment to serve applications.

## Modules

There are two Terraform modules in the `modules` directory:

* environment
* polarstomps-webapp

### environment

The environment module will deploy a collection of resources that logically constitute an opinionated "environment". That is,

1. A VPC that has one public subnet and one private subnet. The public subnet is where publically routable infrastructure goes (load balancers, for example). The private subnet is mostly where Kubernetes worker nodes live.
2. An egress route so that internal services can talk to the Internet.
3. Firewall rules so that my home IP address can SSH into the public subnet.
4. A cloud router.
5. A router NAT.
6. A GKE autopilot cluster with a private worker node pool and a public control plane endpoint that is locked down to my home IP address.

### polarstomps-webapp

The polarstomps-webapp module encapsulates all ancillary infrastructure for the web application. For example, it handles the generation of the SSL certificate for the `a-bridge.app` as well as the creation of the A record.

The creation of GCP resources is split between Terraform and the Kubernetes manifests that deploy the app.

# Getting started

## Dependencies

* Terraform
* Terragrunt
* ArgoCD CLI
* kubectl
* gcloud CLI

### Account Dependencies

This repo requires a GCP account to target and assumes that you have one. You'll need to create a `polarstomps` project and put its project ID in `root.tfvars`.

This repo also uses Terraform Cloud. This part is a bit trickier as the Terraform Cloud backend configuration exists in each `terragrunt.hcl` file and you'll need to edit those to point to your Terraform Cloud configuration (project and workspaces).

### Access

Terraform will create a firewall rule and a whitelist entry for the k8s control plane that allows one IP address access to the public subnet and the plane endpoint.

You'll need to put yours into `root.tfvars` if you want to access anything.

### Domain

The domain for this app was purchased manually through Google (which provisioned the zone automatically). You'll need to purchase your own domain and plug it into the
Polarstomps values file.

## Deploying

Once you have everything setup, you can deploy.

To deploy the VPC and k8s cluster:

``` sh
cd infra-dev/
terragrunt init
terragrunt deploy
```

To deploy the A record for Polarstomps:

``` sh
cd polarstomps-webapp/polarstomps-webapp-dev
terragrunt init
terragrunt deploy
```

### Deploying Polarstomps

Polarstomps is deployed using ArgoCD/k8s manifests [here](https://github.com/howdoicomputer/polarstomps-argo-gcp).

ArgoCD will then pull down that repo and try its best to sync state for the cluster. Part of GKE's offering is that it'll automatically provision a load balancer and route traffic from the spawned pods through it. GKE will also use an ingress annotation to provision a managed certificate for the domain.

### Manual Work

There was some manual work involved:

### Static IP

Creating the static IP address:

``` sh
gcloud compute addresses create polarstomps --global
```

### Domain Name

The domain name was purchased and this provisioned the DNS zone within GCP automatically.

### Project Creation

There is a project module for Terraform but I opted not to use and just created a project manually and specified its ID throughout.

# TODO

* Deploy *something* that uses a StatefulSet
* Have Polarstomps communicate with some hosted GCP service (maybe GCS)
* Maybe deploy a different application that requests a GPU for its workload

---
