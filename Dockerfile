FROM centos:7
LABEL description="Openshift ACME Route Whitelist Updater" \
      repository="https://github.com/djerfy/openshift-acme-whitelist-updater" \
      maintainer="djerfy <djerfy@gmail.com>"

ARG USER=2000
ARG HOMEDIR=/app
WORKDIR ${HOMEDIR}

RUN yum install -y centos-release-scl && \
    yum install rh-python36 && \
    rm -f /usr/bin/python && \
    ln -sfv /opt/rh/rh-python36/root/usr/bin/python3.6 /usr/bin/python && \
    ln -sfv /opt/rh/rh-python36/root/usr/bin/pip3.6 /usr/bin/pip

RUN mkdir -p ${HOMEDIR} && \
    chgrp -R 0 ${HOMEDIR} && \
    chmod -R g=u ${HOMEDIR}

RUN pip install --upgrade pip && \
    pip install pyyaml requests kubernetes openshift

COPY files/ /app
USER ${USER}
CMD ["/usr/bin/python", "/app/route-updater.py"]
