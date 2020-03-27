FROM quay.io/operator-framework/ansible-operator:latest

USER root
RUN yum -y update \
 && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
 && yum -y install python3-boto3 \
 && yum clean all
USER 1001
COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
