FROM hashicorp/terraform:1.2.3@sha256:20bbc15d29c9d1a13e05a3f688789c42a00227c4ea8acd68260e39403093a1f0 as terraform
FROM hashicorp/packer:1.6.6@sha256:523457b5371562c4d9c21621ee85c71c31e7ff53d5ec303a5daf07c55531b84e as packer
FROM library/vault:1.5.0@sha256:2d310383d1a7d5a0808d18f55fb985794c2c3d2d6a0b98d86362b8aacf332d17 as vault
FROM mikefarah/yq:3.4.1@sha256:40c7256194d63079e3f9efad931909d80026400dfa72ab42c3120acd5b840184 as yq
FROM alpine/helm:3.2.4@sha256:47d04364afb9b246484aff708c03e5216295c485d21fafe4c10841d81108700a as helm
FROM library/ubuntu:18.04@sha256:478caf1bec1afd54a58435ec681c8755883b7eb843a8630091890130b15a79af

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
