# Demo-Magic Scripts to install and demo Knative's Serving and Eventing

[![Twitter
Follow](https://img.shields.io/twitter/follow/vmw_rguske?style=social)](https://twitter.com/vmw_rguske)

:pencil: [My Personal Blog](https://rguske.github.io)

Hi curious visitor :wave:

Knative is the most popular platform to run Serverless workload on Kubernetes. It's two building blocks **Serving** and **Eventing** are providing a rich set of features in order to support you in running your Serverless workload **as well as** to build Event-Driven architectures. Implementation-details like e.g. the reactive *Knative Pod Autoscaler* making it possible to scale your workload from n to 0(!) and vice versa. Also, features like *Revisions* and *Routes* making deployment models like *Blue/Green*, *Canary* and *Progressive* available and thus providing great flexibility in shipping your code to production.

This repository provides two demo-scripts I've created to demo Knative's power in the mentioned disciplines. By cloning this repository, you will have two scripts by hand, which will install the two aforementioned building blocks to an existing Kubernetes installation plus demos for each. But don't think about a classical installation script (execute -> finish)! The idea is basically, you execute a script, it'll start typing the first command for you and stops until you execute. Therefore, you can keep focus on your presentation and continue when you are ready. I've e.g. used the scripts multiple times when presenting on Knative. I'm using the popular [Demo Magic](https://github.com/paxtonhare/demo-magic) script/tool to do so.

## :book: Table of Content

- [Using Demo-Magic Scripts to install Knative's Serving and Eventing](#using-demo-magic-scripts-to-install-knatives-serving-and-eventing)
  - [:book: Table of Content](#book-table-of-content)
  - [:computer: CLI Tools](#computer-cli-tools)
  - [:wrench: Preperations](#wrench-preperations)
    - [:label: Knative Release Versions](#label-knative-release-versions)
    - [:passport_control: Load Balancer required](#passport_control-load-balancer-required)
  - [:sparkles: Knative Magic locally on a KinD Cluster](#sparkles-knative-magic-locally-on-a-kind-cluster)
    - [:star: Eventing Demo vSphere-Tag](#star-eventing-demo-vsphere-tag)
  - [:rocket: Execute a Script](#rocket-execute-a-script)

## :computer: CLI Tools

In order not being disrupted by a missing cli tool during the script execution, install (or replace a tool withing the script) the following cli tools:

- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kn](https://knative.dev/docs/install/client/install-kn/)
- [vegeta](https://github.com/tsenart/vegeta)
- [figlet](https://formulae.brew.sh/formula/figlet)
- [lolcat](https://github.com/busyloop/lolcat)
- [helm](https://helm.sh/docs/intro/install/)

## :wrench: Preperations

Clone the repository locally and change into the new directory `knative_serving_eventing_demo_script`.

```shell
git clone git@github.com:rguske/knative_serving_eventing_demo_script.git && cd knative_serving_eventing_demo_script
```

### :label: Knative Release Versions

Open both scripts and adjust the respective release versions for the installations at the beginning of every script. You'll find the latest releases using the links below.

- [Serving](https://github.com/knative/serving/releases/)
- [Net-Contour](https://github.com/knative-sandbox/net-contour/releases)
- [Eventing](https://github.com/knative/eventing/releases)

```shell
# adjust the versions for the serving installation (core and net-contour) in knative_serving.sh
export KN_SERVING='knative-v1.1.1'
export KN_CONTOUR='knative-v1.1.0'

# adjust the version for the eventing installation in knative_eventing.sh
export KN_EVENTING=knative-v1.0.2
```

> Note: I've only tested both scripts successfully with the above release versions.

> Note: If you like to use another [networking-layer](https://knative.dev/docs/install/uninstall/#uninstalling-a-networking-layer) than Contour, modify the sections `04.` as well as `05.` in the `knative_serving.sh` script accordingly.

### :passport_control: Load Balancer required

Because I'm using [Tanzu Kubernetes Grid](https://tanzu.vmware.com/kubernetes-grid) as a Kubernetes runtime, load balancing services is not a topic I have to worry about. Therefore, section `05.` in the `knative_serving.sh` script is expecting that a load balancer will assign an IP address automatically to the Envoy Proxy (`kubectl get service envoy -n contour-external --output 'jsonpath={.status.loadBalancer.ingress[0].ip}'`).


## :sparkles: Knative Magic locally on a KinD Cluster

If you don't have a Kubernetes playground available, check out [Knative on Kind (KonK)](https://github.com/csantanapr/knative-kind).

You are a Fusion or Workstation user? Check out `vctl` to easliy instantiate a KinD cluster locally :eyes: :point_right: [A closer look at VMware's Project Nautilus](https://rguske.github.io/post/a-closer-look-at-vmwares-project-nautilus/)

### :star: Eventing Demo vSphere-Tag

In order to provide a great Event-Driven-Architecture (EDA) experience on vSphere, the `knative_eventing.sh` script will install the [VMware Event Router](https://github.com/vmware-samples/vcenter-event-broker-appliance/tree/development/vmware-event-router) using `helm`, to connect to the vCenter Server event-stream (vCenter = event `provider`) and to provide the stream to a [broker](https://knative.dev/docs/eventing/broker/). For the deployment of the Event-Router, it's important that you enter your vCenter parameters in section `06.` of the `knative_eventing.sh` script.

Section 06:

```yaml
cat << EOF > override.yaml
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
EOF
```

Also, an example function from the official [VEBA](https://github.com/vmware-samples/vcenter-event-broker-appliance) (VMware Event Broker Appliance) repository will be used for the eventing demo. It will apply a specified vSphere Tag to a Virtual Machine after it was powered on (`DrsVmPoweredOnEvent`).

Adjust the values in the `tag_secret.json` file accordingly before starting the `knative_eventing.sh` script.

> Note: Of course the vSphere Tag must also exist before you start the script :wink:

```json5
{
  // vCenter Server address (FQDN or IP)
  "VCENTER_SERVER": "FILL-ME-IN",
  //User with the right persmissions to apply a vSphere Tag
  "VCENTER_USERNAME" : "FILL-ME-IN",
  // Users password
  "VCENTER_PASSWORD" : "FILL-ME-IN",
  // vSphere Tag name
  "VCENTER_TAG_NAME" : "FILL-ME-IN",
  // Possible values are Fail, Ignore or Warn
  "VCENTER_CERTIFICATE_ACTION" : "FILL-ME-IN"
}
```

## :rocket: Execute a Script

Simply start a script by executing e.g. `./knative_serving.sh` on your terminal and confirm the execution of each printed command. I recommend using `tmux` and `watch` (e.g. `watch kubectl get pods -A`) or helpful tools like [k9s](https://github.com/derailed/k9s) or [Octant](https://github.com/vmware-tanzu/octant) to follow the installations on another terminal window.

Have Fun!
