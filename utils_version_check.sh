#!/usr/bin/env bash

declare -a cloud_utils=(
"controlplaneio/kubesec"
"controlplaneio/kubectl-kubesec"
"kubeshark/kubeshark"
"kubernetes/helm"
"chartmuseum/helm-push"
"jkroepke/helm-secrets"
"helm/helm-mapkubeapis"
"databus23/helm-diff"
"mozilla/sops"
"FiloSottile/age"
"derdanne/stern"
"derailed/k9s"
"FairwindsOps/nova"
"FairwindsOps/pluto"
"stedolan/jq"
"mikefarah/yq"
"docker/docker"
"kubevirt/kubevirt"
)

# check GitHub API rate limiting
gh_ratelimit_results=$(curl -si https://api.github.com/users/octocat)
gh_ratelimit_remaining=$(awk '/x-ratelimit-remaining/ { print $2 }' <<< "${gh_ratelimit_results}")
# Remove all new line, carriage return, tab characters
# from the string, to allow integer comparison
gh_ratelimit_remaining="${gh_ratelimit_remaining//[$'\t\r\n ']}"

#gh_ratelimit_reset=$(awk '/x-ratelimit-reset/ { print $2 }' <<< "${gh_ratelimit_results}")

# adding an additional request count for the call in the variable `gcloud_sdk_latest`
gh_need_api_request_count=$(( ${#cloud_utils[@]} + 1 ))

if [[ "${gh_need_api_request_count}" -gt "${gh_ratelimit_remaining}" ]]; then
  echo -e "Rate Limited: ${gh_ratelimit_remaining}/${gh_need_api_request_count} required GitHub API requests remain"
  exit 1
fi

tfile=$(mktemp)

echo "Utility Installed-Version Latest-Version Status" >> "${tfile}"
echo "------- ----------------- -------------- ------" >> "${tfile}"

kubectl_latest=$(curl --silent https://storage.googleapis.com/kubernetes-release/release/stable.txt)
kubectl_installed=$(awk  -F'"' '$0 ~ "KUBECTL_VERSION" { print $2;exit }' Dockerfile)
if [ "${kubectl_installed}" == "${kubectl_latest}" ]; then
  kubectl_status="✓"
  kubectl_util="KUBECTL"
else
  kubectl_status="x"
  kubectl_util="KUBECTL"
fi
echo -e "${kubectl_util} ${kubectl_installed} ${kubectl_latest} ${kubectl_status}" >> "${tfile}"

oc_latest=$(curl --silent https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt |
                          awk '/Version:/ { print $2 }')
oc_installed=$(awk  -F'"' '$0 ~ "OC_VERSION" { print $2;exit }' Dockerfile)
if [ "${oc_installed}" == "${oc_latest}" ]; then
  oc_status="✓"
  oc_util="OC"
else
  oc_status="x"
  oc_util="OC"
fi
echo -e "${oc_util} ${oc_installed} ${oc_latest} ${oc_status}" >> "${tfile}"

gcloud_sdk_latest=$(curl -L --silent "https://api.github.com/repos/GoogleCloudPlatform/cloud-sdk-docker/git/refs/tags" |
                    jq -r '.[].ref | split("/")[2]' | sort -t "." -k1,1n -k2,2n -k3,3n | tail -n1)
gcloud_sdk_installed=$(awk  -F'"' '$0 ~ "GCLOUD_SDK_VERSION" { print $2;exit }' Dockerfile)
if [ "${gcloud_sdk_installed}" == "${gcloud_sdk_latest}" ]; then
  gcloud_sdk_status="✓"
  gcloud_sdk_util="GCLOUD_SDK"
else
  gcloud_sdk_status="x"
  gcloud_sdk_util="GCLOUD_SDK"
fi
echo -e "${gcloud_sdk_util} ${gcloud_sdk_installed} ${gcloud_sdk_latest} ${gcloud_sdk_status}" >> "${tfile}"

for cloud_util in ${cloud_utils[@]}; do
  util_latest=$(curl -L --silent "https://api.github.com/repos/${cloud_util}/releases/latest" | awk -F '"' '/tag_name/{print $4}')
  dockerfile_string=$(echo "${cloud_util}" | awk -F'/' '{ gsub("-","_",$2); print toupper($2) }')
  util_installed=$(awk -v SEARCH="${dockerfile_string}_VERSION" -F'"' '$0 ~ SEARCH { print $2;exit }' Dockerfile)
  if [ "${util_installed}" == "${util_latest}" ]; then
    util_status="✓"
    dockerfile_util="${dockerfile_string}"
  else
    util_status="x"
    dockerfile_util="${dockerfile_string}"
  fi
  echo -e "${dockerfile_util} ${util_installed} ${util_latest} ${util_status}" >> "${tfile}"
done

#cat "${tfile}" | column -t -s' '
column -t -s' ' < "${tfile}"

rm -f "${tfile}"
