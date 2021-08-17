# Direct Volume Migration Proxy Configuration

This document describes expected _TCP_ proxy setup for Direct Volume Migration.

In MTC 1.4.2, we introduced proxy configuration for Direct Volume Migration. Direct connection can be setup between the source and the target cluster through a _TCP_ proxy and the `stunnel_tcp_proxy` variable in the _MigrationController_ CR can be configured to use the proxy: 

_MigrationController_
```sh
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  stunnel_tcp_proxy: http://username:password@ip:port
```

DVM only supports Basic Authentication for the proxy. Moreover, DVM only works behind proxies which can tunnel a TCP connection transparently. HTTP/HTTPS proxies in man-in-the-middle mode will not work. The existing cluster-wide proxies may or may not support this behavior. As a result, the proxy settings for DVM are intentionally kept different from usual proxy configuration in MTC.

## Why not a HTTP/HTTPS proxy?

Direct Volume Migration is enabled by running Rsync between the source and the target cluster over an OpenShift Route. The traffic is encrypted using Stunnel which in itself is a TCP proxy. The Stunnel running on the source cluster initiates a TLS connection with the target Stunnel and transfers data over an encrypted channel. Cluster-wide HTTP/HTTPS proxies in OpenShift are usually configured in man-in-the-middle mode where they negotiate their own TLS session with the outside servers. This does not work with Stunnel. Stunnel requires its TLS session untouched by the proxy essentially making the proxy a transparent tunnel which simply forwards the TCP connection as-is.

### TCP proxy example with Squid

Some HTTP/HTTPS proxies support configuring a transparent TCP tunnel. In this section, we take a look at an example configuration we created for a cluster wide HTTP/HTTPS proxy set up using Squid. 

Squid uses `sslBump` module to bump the SSL connection making the proxy act as a man-in-the-middle:

```sh
http_port 3129 ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=<ca_cert> key=<ca_key> cafile=<ca_file>

ssl_bump bump all
```

For some DVM routes, however, we disable `bump` rules and instead use `splice` directive to create a TCP tunnel. This avoids decrypting the SSL connection and maintains the TLS connection originally created by Stunnel.  

```sh
acl dvmRoute dstdomain <Rsync_Route> 

ssl_bump splice dvmRoute
```

The above configuration allows forwarding the traffic destined to the target cluster's Rsync Route transparently.

### Known Issues

#### Migration fails with error `Upgrade request required` 

The migration Controller uses SPDY protocol to execute commands within remote Pods. If the remote cluster is behind a proxy/firewall which does not support SPDY protocol, the migration controller will fail to execute remote commands. The migration will fail with error message `Upgrade request required`. To solve the issue, the proxy must allow SPDY protocol.

In addition to supporting SPDY protocol, the proxy/firewall also needs to pass `Upgrade` HTTP header to the API server. This header is used by the client to open a websocket connection with the API server. If the `Upgrade` header is blocked by the proxy/firewall, the migration will still fail with the same error message. To solve this issue, the proxy simply needs to forward `Upgrade` header.
