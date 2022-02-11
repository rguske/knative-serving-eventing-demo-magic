#!/bin/bash

########################
# include the magic
########################
. demo-magic.sh

# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# change into the function dir
cd kn-pcli-tag

# hide the evidences
clear

# start
pei "figlet KN EVENTING | lolcat"

# 01. export knative eventing release version | change it if wanted
pei "export KN_EVENTING=knative-v1.0.2"

# 02. deploy knative eventing core and crds
pe "kubectl apply --filename https://github.com/knative/eventing/releases/download/$KN_EVENTING/eventing-crds.yaml \
    && kubectl apply --filename https://github.com/knative/eventing/releases/download/$KN_EVENTING/eventing-core.yaml \
    && kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing"

# hide the evidences
pe clear

# 03. deploy knative in-memory channel (A channel provides an event delivery mechanism that can fan-out received events)
pe "kubectl apply --filename https://github.com/knative/eventing/releases/download/$KN_EVENTING/in-memory-channel.yaml \
    && kubectl apply --filename https://github.com/knative/eventing/releases/download/$KN_EVENTING/mt-channel-broker.yaml \
    && kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing"

# hide the evidences
pe clear

# 04. create a namespace for the example function
pe "kubectl create ns vmware-functions"

# hide the evidences
pe clear

# 05. create a first broker in namespace vmware-functions (brokers = event mesh for collecting a pool of CloudEvents)
pe "kubectl create -f - <<EOF
apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  annotations:
    eventing.knative.dev/broker.class: MTChannelBasedBroker
  name: default
  namespace: vmware-functions
spec:
  config:
    apiVersion: v1
    kind: ConfigMap
    name: config-br-default-channel
    namespace: knative-eventing
EOF"

# hide the evidences
pe clear

# VMware Event-Router deployment
pei "figlet Event-Router  | lolcat"

# 06. create the override.yaml file for the vmware event router deployment
pe "cat << EOF > override.yaml
eventrouter:
  config:
    logLevel: info
  vcenter:
    address: https://<vcenter-server-address> # FQDN or IP
    username: ro-user@vsphere.local # enter your read-only user
    password: 'VMware1!' # enter your super secret password
    insecure: true # specify if the connection is insecure or not
  eventProcessor: knative
  knative:
    destination:
      ref:
        apiVersion: eventing.knative.dev/v1
        kind: Broker
        name: default
        namespace: vmware-functions
EOF"

# hide the evidences
pe clear

# 07. run helm search to get the available event-router versions displayed
pe "helm search repo vmware-veba -l"

# 08. install the vmware event-router via helm
pe "helm install -n vmware-system --create-namespace veba-knative vmware-veba/event-router -f override.yaml --wait"

# hide the evidence
pe clear

# function example deployment
pei "figlet Tagging Function  | lolcat"

# 09. create kn-pcli-tag function secret
pe "kubectl -n vmware-functions create secret generic tag-secret --from-file=TAG_SECRET=tag_secret.json"

# 10. show the function (trigger) config
pe "cat function.yaml"

# hide the evidences
pe clear

# 11. create the kn-ps-slack function
pe "kubectl -n vmware-functions apply -f function.yaml"

# hide the evidences
pe clear

# 12. ensure your test vm is powered off
p "VM powered off?"

# 13. power on the vm
p "Show function (container) log and power on the VM"

# hide the evidences
clear

# end
pei "figlet event-driven rockz!  | lolcat"

# wait max 3 seconds until user presses
PROMPT_TIMEOUT=3
wait