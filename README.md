# kubernetes-terraform

[Terraform](https://terraform.io) formula for creating a [Kubernetes](http://kubernetes.io) cluster running on [Scaleway](https://scaleway.com). Very early, very hacky. Work in progress.

The default configuration includes Kubernetes
[add-ons](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons):
DNS, Dashboard and UI.

## Prerequisites

* appropriate ssh keys set up in Scaleway credentials
* newest version of kubectl (for k8s RBAC)
* ansible

## Getting started:
Clone or download repo.

Copy `sample.terraform.tfvars` to `terraform.tfvars` and insert your variables.

To generate your kubernetes cluster token, run `python -c 'import random; print "%0x.%0x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))'` and set the kubernetes_token variable.


```bash
$ brew update && brew install kubectl terraform

$ terraform plan

$ terraform apply

$ scp root@<master_ip>:/etc/kubernetes/admin.conf .

$ kubectl --kubeconfig ./admin.conf proxy
```
Access the dashboard and api via the following address:

- API: `http://localhost:8001/api/v1`
- Dashboard: `http://localhost:8001/ui`

## Future
- ansible automation for a lot of post-terraform nailing down of scaleway machines
- something else for kubernetes stuff (PV's, ingress etc) 
