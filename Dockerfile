FROM ubuntu:latest
LABEL MAINTAINER "Vasyl Stetsuryn <vasyl@vasyl.org"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Etc/UTC
ENV CONSUL_VERSION 1.9.3
ENV HELM_VERSION 3.5.2
ENV GRPCURL_VERSION 1.8.0
ENV GHZ_VERSION 0.93.0
ENV GRPC_HEALTH_PROBE_VERSION 0.3.6

RUN apt-get update && \
    apt-get -y install sudo \
            python3 \
            python3-dev \
            python3-pip \
            apt-transport-https \
            ca-certificates \
            curl \
            git \
            zlib1g-dev \
            software-properties-common \
            gnupg \
            gnupg2 \
            libstdc++6 \
            gcc \
            g++ \
            bzip2 \
            wget \
            make \
            unzip \
            vim \
            jq \
            less \
            htop \
            nmap \
            net-tools \
            telnet \
            iproute2 \
            iputils-ping \
            libapr1 \
            libapr1-dev \
            libaprutil1 \
            guile-2.0-dev \
            libxml2 \
            libxml2-dev \
            pcre2-utils \
            libpcre2-dev \
            libpcre3-dev \
            libffi-dev \
            libssl-dev \
            libc6-dev && \
    rm -rf /var/cache/apt/*

RUN pip3 install python-hglib requests pika hvac ansible python-consul openshift

RUN groupadd --gid 1000 debug && \
    adduser --gid 1000 --uid 1000 --disabled-password --system --home /home/debug debug && \
    echo "debug ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

### Install kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    rm -rf /var/cache/apt/*

### Install helm
RUN wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -O /tmp/helm.tar.gz && \
    tar zxfv /tmp/helm.tar.gz -C /tmp/ && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm

### Install consul binary
RUN wget "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" -O /tmp/consul.zip && \
    unzip /tmp/consul.zip -d /tmp && \
    mv /tmp/consul /usr/local/bin/consul && \
    chown root:root /usr/local/bin/consul

### Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    bash ./aws/install

### Install grpcurl binary
RUN wget "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz" -O /tmp/grpcurl.tar.gz && \
    tar zxfv /tmp/grpcurl.tar.gz -C /tmp/ && \
    mv /tmp/grpcurl /usr/local/bin/grpcurl && \
    chown root:root /usr/local/bin/grpcurl

RUN curl -sSL "https://github.com/bojand/ghz/releases/download/v${GHZ_VERSION}/ghz-linux-x86_64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/ghz /usr/local/bin && chmod +x /usr/local/bin/ghz

RUN wget -qO /usr/local/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /usr/local/bin/grpc_health_probe

RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list && \
    apt-get update && apt-get -y install mongodb-org-shell mongodb-org-tools

ADD --chown=debug:debug https://raw.githubusercontent.com/grpc/grpc-proto/master/grpc/health/v1/health.proto /tmp/health.proto

WORKDIR /home/debug
USER debug
CMD [ "/bin/bash" ]