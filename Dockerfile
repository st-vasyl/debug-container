FROM ubuntu:jammy
LABEL MAINTAINER "Vasyl Stetsuryn <vasyl@vasyl.org>"

ARG TARGETARCH
ARG TARGETPLATFORM
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Etc/UTC
ENV HELM_VERSION 3.12.0
ENV GRPCURL_VERSION 1.8.7
ENV GHZ_VERSION 0.117.0
ENV GRPC_HEALTH_PROBE_VERSION 0.4.19

RUN apt update && \
    apt -y install sudo \
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
            dnsutils \
            netcat \
            kafkacat \
            net-tools \
            mysql-client \
            redis-tools \
            s3cmd \
            groff \
            telnet \
            iproute2 \
            iputils-ping \
            libapr1 \
            libapr1-dev \
            libaprutil1 \
            libxml2 \
            libxml2-dev \
            pcre2-utils \
            libpcre2-dev \
            libpcre3-dev \
            libffi-dev \
            libssl-dev \
            libc6-dev && \
    rm -rf /var/cache/apt/*

RUN pip3 install python-hglib requests pika hvac ansible python-consul openshift boto3 requests_aws4auth awscli

RUN groupadd --gid 1000 debug && \
    adduser --gid 1000 --uid 1000 --disabled-password --system --home /home/debug debug && \
    echo "debug ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

### Install kubectl
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
    apt update && apt install -y kubectl && \
    rm -rf /var/cache/apt/*

### Install helm
RUN wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" -O /tmp/helm.tar.gz && \
    tar zxfv /tmp/helm.tar.gz -C /tmp/ && \
    mv /tmp/linux-${TARGETARCH}/helm /usr/local/bin/helm

### Install grpcurl binary
SHELL ["/bin/bash", "-c"] 
RUN if [ $TARGETARCH == "amd64" ]; then ARCH="x86_64"; else ARCH="arm64" ; fi && \
    wget "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_${ARCH}.tar.gz" -O /tmp/grpcurl.tar.gz && \
    tar zxfv /tmp/grpcurl.tar.gz -C /tmp/ && \
    mv /tmp/grpcurl /usr/local/bin/grpcurl && \
    chown root:root /usr/local/bin/grpcurl && \
    curl -sSL "https://github.com/bojand/ghz/releases/download/v${GHZ_VERSION}/ghz-linux-${ARCH}.tar.gz" | tar xz -C /tmp && \
    mv /tmp/ghz /usr/local/bin && chmod +x /usr/local/bin/ghz    

RUN wget -qO /usr/local/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-${TARGETARCH} && \
    chmod +x /usr/local/bin/grpc_health_probe

### Install MongoDB client
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb-6.gpg && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org.list && \
    apt update && apt -y install mongodb-org-shell mongodb-org-tools mongodb-atlas mongodb-mongosh

### Install Vault and Consul
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt install vault consul && \
    rm -rf /var/cache/apt/*

ADD --chown=debug:debug https://raw.githubusercontent.com/grpc/grpc-proto/master/grpc/health/v1/health.proto /tmp/health.proto

WORKDIR /home/debug
USER debug
CMD [ "/bin/bash" ]
