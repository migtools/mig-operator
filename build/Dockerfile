FROM quay.io/operator-framework/ansible-operator:v1.31
USER root
RUN pip3.8 --no-cache install --upgrade 'urllib3>=2.7.0' 'pyasn1>=0.6.3'
RUN pip3.8 --no-cache install -U openshift
USER ansible
COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
