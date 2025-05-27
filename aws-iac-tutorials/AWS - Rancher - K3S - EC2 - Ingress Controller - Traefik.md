

This is the `guestbook` example ingress configuration in ArgoCD's test cases.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook-ui-ingress
  namespace: guestbook2
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: traefik
  rules:
    # - host: guestbook.example.com
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: guestbook-ui
            port:
              number: 80
```


