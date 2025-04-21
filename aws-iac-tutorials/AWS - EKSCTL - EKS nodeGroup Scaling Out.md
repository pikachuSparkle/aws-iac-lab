

## Check the NodeGroup's status

```
eksctl get nodegroup --cluster=cluster-demo-1 --region=us-east-1
```

```
eksctl get nodegroup --cluster cluster-demo-1 --region us-east-1 --name demo-nodeGroup-1
```

## Scale the nodes

```
eksctl scale nodegroup --cluster=<cluster-name> --name=<nodegroup-name> --nodes=<desired-size> --nodes-min=<min-size> --nodes-max=<max-size> --region=us-east-1
```

```
eksctl scale nodegroup --cluster=cluster-demo-1  --name=demo-nodeGroup-1 --nodes=2  --nodes-min=2 --nodes-max=2  --region=us-east-1
```

## Check again & validate
```
eksctl get nodegroup --cluster=cluster-demo-1 --region=us-east-1
```
