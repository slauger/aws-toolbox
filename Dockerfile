FROM hashicorp/terraform:1.2.6@sha256:82a29cfa2b977cc471abb0872c73627642e14ff49fa3c24204ee98657e5318fb as terraform
FROM hashicorp/packer:1.8.3@sha256:ac62cbd11b86a43d5efef0e27432ebea282b15a621e8e0e2ade1e1f856400fec as packer
FROM library/vault:1.11.1@sha256:594d69ae0e3f7d8422a99859fd8221d8b558bb65ce561e433d2b25bdfb6d65bd as vault
FROM mikefarah/yq:3.4.1@sha256:40c7256194d63079e3f9efad931909d80026400dfa72ab42c3120acd5b840184 as yq
FROM alpine/helm:3.9.2@sha256:cc53d33e278465c19acde2268641c96651a5386c4c263df24f7bfdc4225d6d69 as helm
FROM library/ubuntu:18.04@sha256:eb1392bbdde63147bc2b4ff1a4053dcfe6d15e4dfd3cce29e9b9f52a4f88bc74

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
