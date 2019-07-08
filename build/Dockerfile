FROM quay.io/operator-framework/ansible-operator:v0.8.1
RUN yum -y update && yum clean all

COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
