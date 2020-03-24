FROM quay.io/operator-framework/ansible-operator:latest

USER root
RUN yum -y update && yum -y install python-boto3 && yum clean all
USER 1001
COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
