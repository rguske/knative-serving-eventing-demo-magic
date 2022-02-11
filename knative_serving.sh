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

# hide the evidences
clear

# start
pei "figlet KN SERVING | lolcat"

# 01. show kubernetes cluster nodes
pei "kubectl get nodes -o wide"

# hide the evidences
pe "clear"

# 02. export knative serving and kn-contour release versions | modify if you'd like to use a different version
pei "export KN_SERVING='knative-v1.1.1'"
pei "export KN_CONTOUR='knative-v1.1.0'"

# 03. install knative serving crds and core components
pe "kubectl apply -f https://github.com/knative/serving/releases/download/$KN_SERVING/serving-crds.yaml \
    && kubectl apply -f https://github.com/knative/serving/releases/download/$KN_SERVING/serving-core.yaml \
    && kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-serving"

# hide the evidences
pe clear

# 04. install contour ingress controller and patch configmap config-network
pe "kubectl apply -f https://github.com/knative/net-contour/releases/download/$KN_CONTOUR/release.yaml"
pe "kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{\"data\":{\"ingress.class\":\"contour.ingress.networking.knative.dev\"}}' \
    && kubectl wait deployment --all --timeout=-1s --for=condition=Available -n contour-external \
    && kubectl wait deployment --all --timeout=-1s --for=condition=Available -n contour-internal"
# kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{"data":{"ingress.class":"contour.ingress.networking.knative.dev"}}' \
# && kubectl wait deployment --all --timeout=-1s --for=condition=Available -n contour-external \
# && kubectl wait deployment --all --timeout=-1s --for=condition=Available -n contour-internal

# hide the evidences
pe clear

# 05. export necessary variables for the config-domain configmap patch | this step requires a Load Balancer which serves your service requests
pe "export EXTERNAL_IP=$(kubectl get service envoy -n contour-external --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')"
pe "echo $EXTERNAL_IP"
# using .nip.io as a domain suffix ensures that local dns resolution works
pe "export KNATIVE_DOMAIN=$EXTERNAL_IP.nip.io"
# to use your own domain suffix, adjust your dns A-Record for the kn service upfront (if you know the assigned Virtual IP from the LB)
# pe "export KNATIVE_DOMAIN=jarvis.tanzu"
# pe "dig -x $EXTERNAL_IP"

# hide the evidences
pe clear

# 06. patch configmap config-domain
pe "kubectl patch configmap -n knative-serving config-domain -p '{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}'"
# the command below patches the configmap with a custom domain suffix
# kubectl patch configmap -n knative-serving config-domain -p '{"data": {"jarvis.tanzu": ""}}'

# check if your dns resolution works
pei "dig $KNATIVE_DOMAIN"

# hide the evidences
pe clear

# 07. create a kubernetes demo namespace
pe "export DEMONS=kn-demo"
pe "kubectl create ns ${DEMONS}"

# 08. create a first app revision
pe "kn service create echo-app --image projects.registry.vmware.com/tanzu_ese_poc/echo-app:1.0 -n ${DEMONS}"

# hide the evidences
pe clear

# 09. curl (watched) the revision with the randomly assigned revision name
pe "watch -n 1 curl -s http://echo-app.kn-demo.${KNATIVE_DOMAIN}"

# hide the evidences
pei clear

# 10. update the revision with a service concurrency limit to 1 to simulate a multi-threaded service and to demonstrate knatives autoscaling capabilities
pe "kn service update echo-app --concurrency-limit=1 -n ${DEMONS}"

# 11. simulate 10 user sessions for 2 seconds
pe "echo 'GET http://echo-app.kn-demo.${KNATIVE_DOMAIN}' | vegeta attack -duration=2s -rate=10 -output=request-single.bin"

# optional: append the following option to show the vegeta results in html
# -output=request-15.bin && vegeta plot -title=RequestResultsSingle request-15.bin > RequestResultsSingle.html && sleep 5s && google-chrome RequestResultsSingle.html

# hide the evidences
pe clear

# 12. set a custom revision name as well as the service concurrency limit back to default
pe "kn service update echo-app --revision-name v1 --env MSG='Who is it?' --concurrency-limit=0 -n ${DEMONS}"

# hide the evidences
pe clear

# 13. instantiate a new revision of the echo-app kn service with a different revision name and change MSG to "its me!"
pe "kn service update echo-app --revision-name v2 --env MSG='Its me!' -n ${DEMONS}"

# hide the evidences
pei clear

# 14. update the kn service with a new revision name and change MSG to "sorry?"
pe "kn service update echo-app --revision-name v3 --env MSG='Sorry?' -n ${DEMONS}"

# hide the evidences
pei clear

# 15. demonstrate traffic splitting between rev v1, v2 and v3
pe "kn service update echo-app -n ${DEMONS} --traffic echo-app-v1=33,echo-app-v2=33,echo-app-v3=34"

# hide the evidences
pei clear

# 16. curl the kn service again but this time the output is showing messages from all three revisions
pe "watch -n 1 curl -s http://echo-app.kn-demo.${KNATIVE_DOMAIN}"

# 17. delete the kn service
pe "kn service delete echo-app -n ${DEMONS}"

# end
pei "figlet SERVING rockz | lolcat"

# wait max 3 seconds until user presses
PROMPT_TIMEOUT=3
wait