FROM hashicorp/terraform:1.2.7@sha256:8e4d010fc675dbae1eb6eee07b8fb4895b04d144152d2ef5ad39724857857ccb as terraform
FROM hashicorp/packer:1.8.3@sha256:ac62cbd11b86a43d5efef0e27432ebea282b15a621e8e0e2ade1e1f856400fec as packer
FROM library/vault:1.11.2@sha256:f2c0f82d1bde88a6608f26468258306e48ac46a4d353db2151e26e0fd00928bb as vault
FROM mikefarah/yq:3.4.1@sha256:40c7256194d63079e3f9efad931909d80026400dfa72ab42c3120acd5b840184 as yq
FROM alpine/helm:3.9.3@sha256:7924d066b0e2072cf42036cb837deb0e4f274a0dc4e41bf99ea66b145821e928 as helm
FROM library/ubuntu:22.04@sha256:34fea4f31bf187bc915536831fd0afc9d214755bf700b5cdb1336c82516d154e

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
