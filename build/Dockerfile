FROM quay.io/operator-framework/ansible-operator:v0.9.0

USER root
RUN yum -y update && yum clean all
RUN yum -y install python-boto3
USER 1001
COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
