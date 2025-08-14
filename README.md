# Debug container

This repository consits of docker image with a bunch of tools to make easier debuging processes in Kubernetes clusters. There're `amd64` and `arm64` architectures available on the same image tag. 

## Software list

Kubernetes:
- kubectl
- consul
- vault
- helm

Amazon:
- awscli
- gcloud-cli

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
- docker

## Usage

The most common workflow is to run 
```bash
kubectl run debug --image-pull-policy=Always --image=stvasyl/debug-container:latest --restart=Never -- sleep 14d
```

When pod become started
```bash
kubectl exec -ti debug -c debug -- /bin/bash
```

You also may add `--overrides='{"spec":{"serviceAccountName":"'serviceaccount-name'"}}'` to debug serviceaccount related issues.


In case if you need to add securityContext with capabilities try to use template like this:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug
spec:
  # serviceAccountName: service-account-name
  restartPolicy: Never
  containers:
    - name: debug
      image: "stvasyl/debug-container:latest"
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

If you want to run a pod with ability to build/pull/push a docker image you can run `debug` container with `dind` container
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug
spec:
  restartPolicy: Never
  containers:
    - name: debug
      image: "stvasyl/debug-container:latest"
      imagePullPolicy: Always
      command:
        - /bin/sleep
        - "14d"
      env:
      - name: DOCKER_HOST
        value: unix:///var/run/docker.sock
      securityContext:
        privileged: true
      resources:
        limits:
          cpu: 200m
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 128Mi
      volumeMounts:
      - name: dind-sock
        mountPath: /var/run
    - name: dind
      image: docker:dind
      imagePullPolicy: Always
      args:
      - dockerd
      - --host=unix:///var/run/docker.sock
      - --group=$(DOCKER_GROUP_GID)
      securityContext:
        privileged: true
      env:
      - name: DOCKER_HOST
        value: unix:///var/run/docker.sock
      - name: DOCKER_GROUP_GID
        value: "1000"
      resources:
        limits:
          cpu: 2
          memory: 4Gi
        requests:
          cpu: 1
          memory: 1Gi
      volumeMounts:
      - name: dind-sock
        mountPath: /var/run
  volumes:
  - name: dind-sock
    emptyDir: {}

```
So, after running you can use docker without additional actions:
```
debug@debug:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```