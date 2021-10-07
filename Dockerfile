FROM hashicorp/terraform:0.12.29@sha256:a55f6894766bed2becfb8717ca33b5d52e7c7863619f17227b931c2d2df104b5 as terraform
FROM hashicorp/packer:1.6.0@sha256:a668ecb91532ae0efda6d23c32e330efd2cc6895017dc253ce73cf45647a9cdb as packer
FROM library/vault:1.8.4@sha256:a75b8996586ddaf57866c3e89fc1fadcecbb8c2b85dc6fb70e3613674d771161 as vault
FROM mikefarah/yq:3.3.2@sha256:85cdee895cf081d0abf41a1decdac2725b33e2cbab2adb84e9998ce15835bc3a as yq
FROM alpine/helm:3.2.4@sha256:47d04364afb9b246484aff708c03e5216295c485d21fafe4c10841d81108700a as helm
FROM library/ubuntu:18.04@sha256:e5dd9dbb37df5b731a6688fa49f4003359f6f126958c9c928f937bec69836320

# basic toolings
RUN apt-get update \
    && apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && add-apt-repository -y "deb https://packages.cloud.google.com/apt/ cloud-sdk-$(lsb_release -cs) main" \
    && apt-get update \
    && apt-get install --no-install-recommends -y make openssh-client curl unzip jq docker-ce kubectl \
    && apt-get install --no-install-recommends -y python3 python3-pip python3-setuptools \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && apt-get clean

# python stuff
COPY requirements.txt /etc/requirements.txt
RUN pip3 install -r /etc/requirements.txt

# aws instance scheduler cli
RUN mkdir -p /opt/scheduler-cli && \
    cd /opt/scheduler-cli && \
    curl --output scheduler-cli.zip https://s3.amazonaws.com/solutions-reference/aws-instance-scheduler/latest/scheduler-cli.zip && \
    unzip scheduler-cli.zip && \
    ls -ali . && \
    rm scheduler-cli.zip && \
    python3 setup.py install

# copy external tools
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=packer /bin/packer /usr/local/bin/packer
COPY --from=vault /bin/vault /usr/local/bin/vault
COPY --from=yq /usr/bin/yq /usr/local/bin/yq
COPY --from=helm /usr/bin/helm /usr/local/bin/helm
