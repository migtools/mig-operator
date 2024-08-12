FROM quay.io/operator-framework/ansible-operator:v1.30
USER root
RUN pip3.8 --no-cache install -U openshift
USER ansible
COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
