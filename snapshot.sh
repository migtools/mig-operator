#!/usr/bin/env bash
if [[ "$1" == "" ]]; do
  echo "First argument must be the snapshot tag, received nothing..."
  echo "Example: snapshot.sh sprint9"
  exit 1
done

tag=$1

docker pull quay.io/ocpmigrate/mig-controller:latest
docker pull quay.io/ocpmigrate/mig-ui:latest
docker pull quay.io/ocpmigrate/mig-operator:latest
docker pull quay.io/ocpmigrate/migration-plugin:latest
docker pull quay.io/ocpmigrate/velero:fusor-dev
docker pull quay.io/ocpmigrate/velero-restic-restore-helper:latest

docker tag quay.io/ocpmigrate/mig-controller:latest quay.io/ocpmigrate/mig-controller:${tag}
docker tag quay.io/ocpmigrate/mig-ui:latest quay.io/ocpmigrate/mig-ui:${tag}
docker tag quay.io/ocpmigrate/mig-operator:latest quay.io/ocpmigrate/mig-operator:${tag}
docker tag quay.io/ocpmigrate/migration-plugin:latest quay.io/ocpmigrate/migration-plugin:${tag}
docker tag quay.io/ocpmigrate/velero:fusor-dev quay.io/ocpmigrate/velero:${tag}
docker tag quay.io/ocpmigrate/velero-restic-restore-helper:latest quay.io/ocpmigrate/velero-restic-restore-helper:${tag}

docker push quay.io/ocpmigrate/mig-controller:${tag}
docker push quay.io/ocpmigrate/mig-ui:${tag}
docker push quay.io/ocpmigrate/mig-operator:${tag}
docker push quay.io/ocpmigrate/migration-plugin:${tag}
docker push quay.io/ocpmigrate/velero:${tag}
docker push quay.io/ocpmigrate/velero-restic-restore-helper:${tag}
