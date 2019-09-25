# Downstream operator testing helper scripts

## Manually mirroring images

Make sure to `oc login` to your target cluster where you are going to mirror
your images.

`cp my_var.ex` to `my_var`, set the downstream registry to the brew registry,
and update the image tags to the ones you want to mirror.

Run `expose_cluster_registry.sh` to expose the target cluster's docker registry.
It will also create and permission a ServiceAccount for you to use to push.
Ensure that you have added the resulting exposed registry route to your docker
daemon's insecure registries and reloaded your docker daemon.

Docker login to the newly exposed route using the `docker_login_exposed_registry.sh` script.

You should be ready to mirror images from downstream build servers into your
target cluster at this point. Run `mirror_downstream_mig_images.sh`.
