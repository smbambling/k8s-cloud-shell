FROM --platform=linux/amd64 ubuntu:22.04

MAINTAINER Steven Bambling <smbambling@gmail.com>

# Metadata
LABEL Remarks="ARIN Cloud Shell Kubernetes Tooling"

# Note: Latest version of GCloud SDK can be found at:
# https://github.com/GoogleCloudPlatform/cloud-sdk-docker/tags
ENV GCLOUD_SDK_VERSION="427.0.0"

# Note: Latest version of kubectl may be found at:
# https://storage.googleapis.com/kubernetes-release/release/stable.txt
ENV KUBECTL_VERSION="v1.28.2"

# Note: Latest version of oc may be found at:
# https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt
ENV OC_VERSION="4.13.13"

# Note: Latest version of oc may be found at:
# https://github.com/kubevirt/kubevirt/releases
ENV KUBEVIRT_VERSION="v1.0.0"

# Note: Latest version of kubesec may be found at:
# https://github.com/controlplaneio/kubesec/releases
ENV KUBESEC_VERSION="v2.13.0"

# Note: Latest version of kubectl-kubesec may be found at:
# https://github.com/controlplaneio/kubectl-kubesec/releases
ENV KUBECTL_KUBESEC_VERSION="v1.1.0"

# Note: Latest version of kubeshark may be found at:
# https://github.com/kubeshark/kubeshark/releases
ENV KUBESHARK_VERSION="50.4"

# Note: Latest version of helm may be found at:
# https://github.com/kubernetes/helm/releases
ENV HELM_VERSION="v3.12.3"

# Note: Latest version of the helm push plugin may be found at:
# https://github.com/chartmuseum/helm-push
ENV HELM_PUSH_VERSION="v0.10.4"

# Note: Latest version of the helm secrets plugin may be found at:
# https://github.com/jkroepke/helm-secrets
ENV HELM_SECRETS_VERSION="v4.5.1"

# Note: Latest version of the helm mapkubeapis plugin may be found at:
# https://github.com/helm/helm-mapkubeapis#helm-mapkubeapis-plugin
ENV HELM_MAPKUBEAPIS_VERSION="v0.4.1"

# Note: Latest version of the helm diff plugin may be found at:
# https://github.com/databus23/helm-diff
ENV HELM_DIFF_VERSION="v3.8.1"

# Note: Latest version of sops may be found at:
# https://github.com/mozilla/sops/releases
ENV SOPS_VERSION="v3.8.0"

# Note: Latest version of age mayb be found at:
# https://github.com/FiloSottile/age/releases
ENV AGE_VERSION="v1.1.1"

# Note: Latest version of stern may be found at:
# https://github.com/derdanne/stern
ENV STERN_VERSION="v2.6.1"

# Note: Lastest version of nova may be found at:
# https://github.com/FairwindsOps/nova/releases
ENV NOVA_VERSION="v3.7.0"

# Note: Lastest version of pluto may be found at:
# https://github.com/FairwindsOps/pluto/releases
ENV PLUTO_VERSION="v5.18.4"

# Note: Latest versio of k9s may be found at:
# https://github.com/derailed/k9s/releases
ENV K9S_VERSION="v0.27.4"

# Note: Latest version of jq may be found at:
# https://github.com/stedolan/jq/releases/
ENV JQ_VERSION="jq-1.7"

# Note: Latest version of yq may be found at:
# https://github.com/mikefarah/yq/releases
ENV YQ_VERSION="v4.35.1"

# Note: Latest version of Docker for x86_64 may be found at:
# https://download.docker.com/linux/static/stable/x86_64/
# https://github.com/moby/moby/releases or https://github.com/docker/docker/releases
ENV DOCKER_VERSION="v24.0.6"

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bash bash-completion git curl dnsutils vim less tree apt-transport-https \
  findutils util-linux bsdmainutils ca-certificates wget unzip expect rsync gnupg openssh-client && \
  apt-get -y clean && \
  apt-get -y autoremove && \
  rm -rf /var/lib/apt/lists/*

# Documenation: https://cloud.google.com/sdk/docs/install#deb -- Docker Tip: section
# Install gcloud google-cloud-sdk-gke-gcloud-auth-plugin
# Note: NOT installing google-cloud-cli until needed
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
  tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && \
  apt-get update -y && \
  apt-get install google-cloud-sdk-gke-gcloud-auth-plugin="${GCLOUD_SDK_VERSION}-0" -y && \
  echo "USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc

RUN wget -q https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz && \
  tar -zxvf age-${AGE_VERSION}-linux-amd64.tar.gz && \
  mv age/age /usr/local/bin && \
  mv age/age-keygen /usr/local/bin && \
  rm -f age-${AGE_VERSION}-linux-amd64.tar.gz && \
  rm -rf age && \
  chmod +x /usr/local/bin/age && \
  chmod +x /usr/local/bin/age-keygen

RUN wget -q -O /usr/local/bin/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod +x /usr/local/bin/kubectl

RUN wget -q https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz \
  && mkdir openshift-client-linux \
  && tar -zxvf openshift-client-linux-${OC_VERSION}.tar.gz -C openshift-client-linux \
  && mv openshift-client-linux/oc /usr/local/bin \
  && chmod +x /usr/local/bin/oc \
  && rm -f openshift-client-linux-${OC_VERSION}.tar.gz \
  && rm -rf openshift-client-linux

RUN wget -q -O /usr/local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64 \
  && chmod +x /usr/local/bin/virtctl

# Install older kubectl to allow creating job on clusters older then 1.21 via API CRONJOB v1beta1
RUN wget -q -O /usr/local/bin/kubectl116 \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl \
  && chmod +x /usr/local/bin/kubectl116

RUN wget -q https://github.com/controlplaneio/kubectl-kubesec/releases/download/${KUBECTL_KUBESEC_VERSION}/kubectl-kubesec_linux_amd64.tar.gz && \
  mkdir kubectl-kubesec && tar -zxvf kubectl-kubesec_linux_amd64.tar.gz -C kubectl-kubesec && \
  mkdir -p ~/.kube/plugins/scan && \
  mv kubectl-kubesec/kubectl-scan ~/.kube/plugins/scan/kubectl-scan && \
  rm -rf kubectl-kubesec kubectl-kubesec_linux_amd64.tar.gz

RUN wget -q https://github.com/controlplaneio/kubesec/releases/download/${KUBESEC_VERSION}/kubesec_linux_amd64.tar.gz && \
  mkdir kubesec && tar -zxvf kubesec_linux_amd64.tar.gz -C kubesec && \
  chmod +x kubesec/kubesec && mv kubesec/kubesec /usr/local/bin/ && \
  rm -rf kubesec kubesec_linux_amd64.tar.gz

RUN wget -q -O /usr/local/bin/kubeshark https://github.com/kubeshark/kubeshark/releases/download/${KUBESHARK_VERSION}/kubeshark_linux_amd64 \
&& chmod +x /usr/local/bin/kubeshark

RUN wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
  tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz && \
  mv linux-amd64/helm /usr/local/bin && \
  rm -f helm-${HELM_VERSION}-linux-amd64.tar.gz && \
  rm -rf linux-amd64 && \
  chmod +x /usr/local/bin/helm

RUN wget -q -O /usr/local/bin/sops \
  https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64 && \
  chmod 0755 /usr/local/bin/sops && \
  chown root:root /usr/local/bin/sops

RUN wget -q -O /usr/local/bin/stern \
  https://github.com/derdanne/stern/releases/download/${STERN_VERSION}/stern_linux_amd64 && \
  chmod +x /usr/local/bin/stern

RUN wget -q https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz && \
  mkdir k9s && tar -zxvf k9s_Linux_amd64.tar.gz -C k9s && \
  chmod +x k9s/k9s && mv k9s/k9s /usr/local/bin/ && \
  rm -rf k9s k9s_Linux_amd64.tar.gz

ENV HELM_HOME=/usr/local/helm
RUN mkdir -p /usr/local/helm/plugins && \
  helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} && \
  helm plugin install https://github.com/chartmuseum/helm-push --version ${HELM_PUSH_VERSION} && \
  helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
  helm plugin install https://github.com/helm/helm-mapkubeapis --version ${HELM_MAPKUBEAPIS_VERSION}

RUN wget -q "https://github.com/FairwindsOps/nova/releases/download/${NOVA_VERSION}/nova_${NOVA_VERSION#v}_linux_amd64.tar.gz" && \
  mkdir /tmp/nova && \
  tar -zxvf nova_${NOVA_VERSION#v}_linux_amd64.tar.gz -C /tmp/nova && \
  mv /tmp/nova/nova /usr/local/bin && \
  rm -f nova_${NOVA_VERSION#v}_linux_amd64.tar.gz && \
  rm -rf /tmp/nova && \
  chmod +x /usr/local/bin/nova

RUN wget -q "https://github.com/FairwindsOps/pluto/releases/download/${PLUTO_VERSION}/pluto_${PLUTO_VERSION#v}_linux_amd64.tar.gz" && \
  mkdir /tmp/pluto && \
  tar -zxvf pluto_${PLUTO_VERSION#v}_linux_amd64.tar.gz -C /tmp/pluto && \
  mv /tmp/pluto/pluto /usr/local/bin && \
  rm -f pluto_${PLUTO_VERSION#v}_linux_amd64.tar.gz && \
  rm -rf /tmp/pluto && \
  chmod +x /usr/local/bin/pluto

RUN wget -q -O /usr/local/bin/jq \
  https://github.com/stedolan/jq/releases/download/${JQ_VERSION}/jq-linux64 \
  && chmod +x /usr/local/bin/jq

RUN wget -q -O /usr/local/bin/yq \
  https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
  && chmod +x /usr/local/bin/yq

RUN wget -q "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION#?}.tgz" && \
    tar -zxvf "docker-${DOCKER_VERSION#?}.tgz" && \
    mv docker/docker /usr/bin && \
    rm -f "docker-${DOCKER_VERSION#?}.tgz" && \
    rm -rf docker && \
    chmod +x /usr/bin/docker

RUN mkdir /root/keys

RUN echo "PROMPT_COMMAND='history -a'" >> ~/.bashrc
RUN echo "PS1='🐳  \[\033[1;36m\]\h \[\033[1;36m\]# \[\033[0m\]'" >> ~/.bashrc
RUN echo "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc
RUN echo "source <(kubectl completion bash)" >> ~/.bashrc
RUN echo "source <(helm completion bash | sed '/WARNING: Kubernetes configuration/d')" >> ~/.bashrc

WORKDIR /helm-vars

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

ENV GPG_TTY=/dev/console
CMD bash
