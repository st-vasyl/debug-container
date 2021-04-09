# Debug container

This repository consits of docker image with a bunch of tools to make easier debuging process in Kubernetes clusters. 

## Software list

Kubernetes:
- kubectl
- consul
- vault
- helm

Amazon:
- awscli

gRPC:
- grpcurl
- grpc_health_probe
- ghz

Network:
- dig
- nslookup
- netcat
- telnet
- netstat
- ifconfig
- route
- nmap
- wget
- curl

Other:
- python
- unzip
- vim
- jq
- git
- gcc/g++


## Usage

The most common workflow is to run 
```bash
kubectl run debug-container --image-pull-policy=Always --image=madguru/debug-container:latest --restart=Never -- sleep 1d
```

When pod become started
```bash
kubectl exec --container debug-container -ti debug-container -- /bin/bash
```

You also may add `--serviceaccount=serviceaccount-name` to debug serviceaccount related issues.


In case if you need to add securityContext with capabilities try to use template like this:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-container
spec:
  # serviceAccountName: service-account-name
  restartPolicy: Never
  containers:
    - name: debug-container
      image: "madguru/debug-container:latest"
      imagePullPolicy: Always
      command:
        - /bin/sleep
        - "1d"
      securityContext:
        capabilities:
          add:
            - IPC_LOCK # add more if you need
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi
```
