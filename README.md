# K8S Cloud Shell Docker Image

## Introduction

This repository contains the needed requirements to build a Docker image that provides a version consistent toolset.

> This container does not have any sensitive information embedded such as Kubernetes kubeconfig file, or AGE keys. These need to be mounted in order for utilities such as Helm and Kubectl to provide credentials for access to resources.



## Bundled Utilities / Items

| Tool                                                         | Version                         |
| ------------------------------------------------------------ | ------------------------------- |
| [kubectl](https://storage.googleapis.com/kubernetes-release/release/stable.txt) | v1.28.2 |
| [oc](https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt) | 4.13.13 |
| [Kubevirt (virtctl)](https://github.com/kubevirt/kubevirt/releases) | v1.0.0 |
| [GCloud SDK / gke-gcloud-auth-plugin](https://github.com/GoogleCloudPlatform/cloud-sdk-docker/tags) | 427.0.0 |
| [kubectl-kubesec](https://github.com/controlplaneio/kubectl-kubesec/releases)   | v1.1.0  |
| [kubesec](https://github.com/controlplaneio/kubesec/releases) | v2.13.0     |
| [kubeshark](https://github.com/kubeshark/kubeshark/releases) | 50.4 |
| [helm](https://github.com/kubernetes/helm/releases)          | v3.12.3 |
| [Helm Push (Plugin)](https://github.com/chartmuseum/helm-push) | v0.10.4               |
| [Helm Secrets (Plugin)](https://github.com/jkroepke/helm-secrets) | v4.5.1 |
| [Helm Diff (Plugin)](https://github.com/databus23/helm-diff) | v3.8.1                 |
| [Helm mapkubeapis (Plugin)](https://github.com/helm/helm-mapkubeapis#helm-mapkubeapis-plugin) | v0.4.1 |
| [sops](https://github.com/mozilla/sops/releases)             | v3.8.0                          |
| [age](https://github.com/FiloSottile/age/releases)           | v1.1.1                       |
| [stern](https://github.com/derdanne/stern)                   | v2.6.1                    |
| [k9s](https://github.com/derailed/k9s/releases)              | v0.27.4    |
| [nova](https://github.com/FairwindsOps/nova/releases) | v3.7.0                |
| [pluto](https://github.com/FairwindsOps/pluto/releases) | v5.18.4 |
| [jq](https://github.com/stedolan/jq/releases/)               | jq-1.7                          |
| [yq](https://github.com/mikefarah/yq/releases)               | v4.35.1      |
| [docker](https://download.docker.com/linux/static/stable/x86_64/) | v24.0.6 |
|  |  |



## Docker-Entrypoint

In addition to the utilities bundled in the container the docker-entrypoint.sh script will perform the following actions

#### AGE Utilities

If an age key file is passphrase-protected using age it can be decrypted by setting the environment variables `AGE_KEY` and `AGE_KEY_PASSPHRASE`. 

* `AGE_KEY`:  The full path of the key file mounted within the container
* `AGE_KEY_PASSPHRASE`: The passphrase used to decrypt the `AGE_KEY` file.

The `AGE_KEY` is decrypted to `$HOME/.config/sops/age/keys.txt`, the default location SOPS will look for a corresponding identity



## Sample Usage

### Simple Container Shell Aceess

```bash
docker run -it --rm --hostname k8s-cloud-shell k8s-cloud-shell
```

### Container Shell Access w/ kubeconfig

A directory containing a kubeconfig can be mounted as a volume within the container for the root user to allow the included utilities to access resources

```bash
docker run -it --rm --hostname k8s-cloud-shell -v ${HOME}/.kube:/root/.kube k8s-cloud-shell
```

### Pass Commands To The Container

In addition to getting shell access into the container commands can be passed for the container to run. Any command after container name will be passed into the container to be run

```bash
docker run -it --rm --hostname k8s-cloud-shell -v ${HOME}/.kube:/root/.kube k8s-cloud-shell ls
```

### Advanced ACS Cluster Config Usage

You can leverage the Docker `--env-file` option to load multiple environment variables into the container. The env-file can also be sourced before calling `docker run` to assit in mounting the needed volumes. 

```bash
$ cat ${HOME}/.k8s-cloud-shell/localk3s
HELM_VAR_REPO="<HELM-REPO FULL REPO PATH>"
# Relative path to age keypair file
AGE_KEY="<AGE .KEY FILE FULL REPO PATH>"
# The age keyfile passphrase for the localci environment
AGE_KEY_PASSPHRASE="<AGE environment key passphrase>"
# The kubeconfig file environment/cluster to allow access
KUBECONFIG_FILE="${HOME}/.kube/<CLUSTER KUBECONFIG FILE>"
```

```bash
myenv="${HOME}/.k8s-cloud-shell/myClusterConfig" &&\
source "$myenv" &&\
docker run -it --rm --hostname arin-cloud-shell --env-file "$myenv" -v "${HELM_VAR_REPO}":/helm-vars \
-v "${KUBECONFIG_FILE}":/root/.kube/config:ro k8s-cloud-shell
```



## Development

### Local Image Build

See [the Docker documentation](https://docs.docker.com/engine/reference/commandline/tag/) for tag details.

1. Build the Docker image:

```bash
TAG=$(cat VERSION) &&
docker build --progress=plain -t k8s-cloud-shell:"${TAG}" .
```
