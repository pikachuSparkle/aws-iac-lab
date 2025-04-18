## NOTES:
- Operator is "controller" of the es cluster.
- Operator has the knowledge of maintances.
- The specific logic need to be read in the operator codes...

## Problem Describtion:

The ECK-based Elasticsearch cluster ssl certificates have expired and needs to be updated. This should be a bug of the ECK operator, because the certificate should be updated by the operator automatically.

```
curl -u "elastic:BBBBBBBBBBBBBBBBBBBBB" -k "https://127.0.0.1:9200/_ssl/certificate"
```

```
[
  {
    "path": "/usr/share/elasticsearch/config/http-certs/ca.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-http, OU=quickstart",
    "serial_number": "a8192ce6fbfe6993e789ec51bf822d7b",
    "has_private_key": false,
    "expiry": "2025-10-12T06:47:41.000Z",
    "issuer": "CN=quickstart-http, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/http-certs/tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-http, OU=quickstart",
    "serial_number": "a8192ce6fbfe6993e789ec51bf822d7b",
    "has_private_key": false,
    "expiry": "2025-10-12T06:47:41.000Z",
    "issuer": "CN=quickstart-http, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/http-certs/tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-es-http.default.es.local, OU=quickstart",
    "serial_number": "d055aad035f6f8904d3377b9ba6dfe9d",
    "has_private_key": true,
    "expiry": "2025-10-12T06:47:41.000Z",
    "issuer": "CN=quickstart-http, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-certs/ca.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-transport, OU=quickstart",
    "serial_number": "8f4d7454e982841fc7edca56f186b72c",
    "has_private_key": false,
    "expiry": "2025-10-12T06:47:41.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-certs/quickstart-es-default-0.tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-transport, OU=quickstart",
    "serial_number": "8f4d7454e982841fc7edca56f186b72c",
    "has_private_key": false,
    "expiry": "2025-10-12T06:47:41.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-certs/quickstart-es-default-0.tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-es-default-0.node.quickstart.default.es.local, OU=quickstart",
    "serial_number": "d0b92b716082ba9eff80cc2b5b601df5",
    "has_private_key": true,
    "expiry": "2025-10-12T06:50:41.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-remote-certs/ca.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-transport, OU=quickstart",
    "serial_number": "8f4d7454e982841fc7edca56f186b72c",
    "has_private_key": false,
    "expiry": "2025-10-12T06:47:41.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  }
]

```
## Prerequisites:

- AWS EKS 1.30
- aws-ebs-csi-driver
- ECK 1.24 + ElasticSearch 8.15

## Create EKS Cluster
[[AWS - EKSCTL - EKS Cluster Deployment with EKSCTL]]

## aws-ebs-csi-driver Installation
[[AWS - EKS - StorageClass - aws-ebs-csi-driver Installation]]

## ECK Operator & ElasticSearch Deployment
[[AWS - EKS - Operator - ECK - elasticsearch & kibana quickstart deployment]]

## Prepare the testbed

```
PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
```

```
# test on the cluster nodes
curl -u "elastic:$PASSWORD" -k "https://quickstart-es-http:9200"
```

```
kubectl port-forward service/quickstart-es-http 9200
```

```
# test on the client
curl -u "elastic:$PASSWORD" -k "https://localhost:9200"
```

```
{
  "name" : "quickstart-es-default-0",
  "cluster_name" : "quickstart",
  "cluster_uuid" : "XqWg0xIiRmmEBg4NMhnYPg",
  "version" : {...},
  "tagline" : "You Know, for Search"
}
```


```
# checking the ssl certificate expiry
curl -u "elastic:BBBBBBBBBBBBBBBBBBBBBBBB" -k "https://127.0.0.1:9200/_ssl/certificate"
```

```
root@ip-172-31-45-201:~# kubectl get secret
NAME                                       TYPE     DATA   AGE
quickstart-es-default-es-config            Opaque   1      8m52s
quickstart-es-default-es-transport-certs   Opaque   3      8m53s
quickstart-es-elastic-user                 Opaque   1      8m54s
quickstart-es-file-settings                Opaque   1      8m53s
quickstart-es-http-ca-internal             Opaque   2      8m53s
quickstart-es-http-certs-internal          Opaque   3      8m53s
quickstart-es-http-certs-public            Opaque   2      8m53s
quickstart-es-internal-users               Opaque   5      8m54s
quickstart-es-remote-ca                    Opaque   1      8m53s
quickstart-es-transport-ca-internal        Opaque   2      8m53s
quickstart-es-transport-certs-public       Opaque   1      8m53s
quickstart-es-xpack-file-realm             Opaque   4      8m54s
```

## "Delete" all of the secrets in default namespace & "delete" the pods of sts (rollout restart)

NOTES:
- the secrets and pod will be recreate automated
- the `elastic` user's password will be changed as `quickstart-es-elastic-user ` deleted
- the certificates's `expiry` will be extended

```
quickstart-es-default-es-config            Opaque   1     20s
quickstart-es-default-es-transport-certs   Opaque   3     17s
quickstart-es-elastic-user                 Opaque   1     20s
quickstart-es-file-settings                Opaque   1     20s
quickstart-es-http-ca-internal             Opaque   2     18s
quickstart-es-http-certs-internal          Opaque   3     18s
quickstart-es-http-certs-public            Opaque   2     18s
quickstart-es-internal-users               Opaque   5     19s
quickstart-es-remote-ca                    Opaque   1     17s
quickstart-es-transport-ca-internal        Opaque   2     17s
quickstart-es-transport-certs-public       Opaque   1     17s
quickstart-es-xpack-file-realm             Opaque   4     19s
```

```
[
  {
    "path": "/usr/share/elasticsearch/config/http-certs/ca.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-http, OU=quickstart",
    "serial_number": "9cf7105913698ddefcf8f7f6c13a1881",
    "has_private_key": false,
    "expiry": "2025-10-12T07:00:46.000Z",
    "issuer": "CN=quickstart-http, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/http-certs/tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-http, OU=quickstart",
    "serial_number": "9cf7105913698ddefcf8f7f6c13a1881",
    "has_private_key": false,
    "expiry": "2025-10-12T07:00:46.000Z",
    "issuer": "CN=quickstart-http, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/http-certs/tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-es-http.default.es.local, OU=quickstart",
    "serial_number": "c02dfef2fceb5df7ff2bc86ac9d9dc97",
    "has_private_key": true,
    "expiry": "2025-10-12T07:00:46.000Z",
    "issuer": "CN=quickstart-http, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-certs/ca.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-transport, OU=quickstart",
    "serial_number": "7088486e050fe97715dab8703b5c902b",
    "has_private_key": false,
    "expiry": "2025-10-12T07:00:47.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-certs/quickstart-es-default-0.tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-transport, OU=quickstart",
    "serial_number": "7088486e050fe97715dab8703b5c902b",
    "has_private_key": false,
    "expiry": "2025-10-12T07:00:47.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-certs/quickstart-es-default-0.tls.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-es-default-0.node.quickstart.default.es.local, OU=quickstart",
    "serial_number": "e4805a2936129b9978d890c47c900521",
    "has_private_key": true,
    "expiry": "2025-10-12T07:03:11.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  },
  {
    "path": "/usr/share/elasticsearch/config/transport-remote-certs/ca.crt",
    "format": "PEM",
    "alias": null,
    "subject_dn": "CN=quickstart-transport, OU=quickstart",
    "serial_number": "7088486e050fe97715dab8703b5c902b",
    "has_private_key": false,
    "expiry": "2025-10-12T07:00:47.000Z",
    "issuer": "CN=quickstart-transport, OU=quickstart"
  }
]
```
