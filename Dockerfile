FROM hashicorp/terraform:0.12.28@sha256:19a84a76564c9bea081b405f458a51107cf2abbafba34af2f02774e72d551ad1 as terraform
FROM hashicorp/packer:1.5.5@sha256:5ebe2fff60ee439d251f2bcbbb71efef6918439dfd04415fc1ab5bd5a212c591 as packer
FROM library/vault:1.4.0@sha256:b8c73943dd14c56dda07500274232daca304d34598ed2cdbe0b6919bce9d72e3 as vault
FROM mikefarah/yq:2.4.2@sha256:c47d38e1ef155438b000e31c24ffa5d90ea7235eeace679e60b84b09d75b6041 as yq
FROM alpine/helm:3.1.2@sha256:721f3b3073f0e7ed7e0ba48794310c5e532ff7175cfa448fee2e529f7f383a9f as helm
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
