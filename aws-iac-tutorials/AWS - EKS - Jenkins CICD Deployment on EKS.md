## 0. References:
https://vocus.cc/article/65b74e54fd89780001fb1221

## 1.  Create the EKS cluster & Amazon EBS CSI driver

[[AWS - EKS - EKS Cluster Deployment with EKSCTL]]

[[AWS - EKS - aws-ebs-csi-driver Installation]]

## 2. Jenkins Master Deploy

All the components of Jenkins will run in the K8S cluster.

```
#---------------------------------------------------
# S2-1. create namespace
#---------------------------------------------------
[master]# kubectl create ns jenkinspoc
```

```
#---------------------------------------------------
# S2-2. create service account
#---------------------------------------------------
[master]# vim jenkinspoc-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:  
  name: jenkins-admin  
  namespace: jenkinspoc
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins
  namespace: jenkinspoc
  labels:
    "app.kubernetes.io/name": 'jenkins'
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get","list","watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-role-binding
  namespace: jenkinspoc
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins-admin
  namespace: jenkinspoc

[master]# kubectl create -f jenkinspoc-sa.yaml -n jenkinspoc
serviceaccount/jenkins-admin created
role.rbac.authorization.k8s.io/jenkins created
rolebinding.rbac.authorization.k8s.io/jenkins-role-binding created

[master]# kubectl get sa -n jenkinspoc

```

```
#---------------------------------------------------
# S2-3. provision master's volume for persistent storage
#---------------------------------------------------
[master]# vim jenkinspoc-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pv-claim
spec:
  storageClassName: managed-nfs-storage/gp2/local-path/ebs-sc
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

[master]# kubectl create -f jenkinspoc-pvc.yaml -n jenkinspoc
[master]# kubectl get pvc -n jenkinspoc

```

```
#---------------------------------------------------
# S2-4. Deploy Jenkins master
#---------------------------------------------------
[master]# vim jenkinspoc-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccountName: jenkins-admin
      securityContext:
            fsGroup: 1000 
            runAsUser: 1000
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts
          resources:
            limits:
              memory: "2Gi"
              cpu: "1000m"
            requests:
              memory: "500Mi"
              cpu: "500m"
          ports:
            - name: httpport
              containerPort: 8080
            - name: jnlpport
              containerPort: 50000
          livenessProbe:
            httpGet:
              path: "/login"
              port: 8080
            initialDelaySeconds: 90
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 5
          readinessProbe:
            httpGet:
              path: "/login"
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          volumeMounts:
            - name: jenkins-data
              mountPath: /var/jenkins_home         
      volumes:
        - name: jenkins-data
          persistentVolumeClaim:
              claimName: jenkins-pv-claim

[master]# kubectl create -f jenkinspoc-deploy.yaml -n jenkinspoc
[master]# kubectl get pod -n jenkinspoc

```

```
#---------------------------------------------------
# S2-5. create svc
#---------------------------------------------------
[master]# vim jenkinspoc-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/path:   /
      prometheus.io/port:   '8080'
spec:
  selector: 
    app: jenkins
  type: NodePort  
  ports:
    - name: httpport
      port: 8080
      targetPort: 8080
      nodePort: 32003
    - name: jnlpport
      port: 50000
      targetPort: 50000

[master]# kubectl create -f jenkinspoc-svc.yaml -n jenkinspoc
[master]# kubectl get all
[master]# kubectl get svc
NAME        TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)      AGE
service/jenkins-service   NodePort   10.109.168.87   <none>        8080:32003/TCP,50000:30779/TCP   30s

```

```
#---------------------------------------------------
# S2-6. Obtain admin passowrd
#---------------------------------------------------
[master]# kubectl get pod -n jenkinspoc
[master]# kubectl exec jenkins-deployment-bdf778654-br6mv -n jenkinspoc -- cat /var/jenkins_home/secrets/initialAdminPassword
b1a8117e9a364353855ebfe03b3308be

http://nodePublicIP:32003
admin/P@ssw0rd
```

## 3. Plugins Install

```
#---------------------------------------------
# S3-1. Install Suggestion plugin as the dashboard instructions
#---------------------------------------------

```

```
#---------------------------------------------
# S3-2. Install kubernetes plugin
#---------------------------------------------
Manage Jenkins > Plugins > Available plugins > "Kubernetes" > Install
```

## 4. Jenkins Master Configuration

```
#---------------------------------------------
# S4-1. create cloud
#---------------------------------------------
Manage Jenkins > Clouds > New cloud > Name: K8s-pipeline (select "Kubernetes") > Create
```

```
#---------------------------------------------
# S4-2. create credentials
# 因為全部都部署在同一座k8s，透過ServiceAccount的授權
#---------------------------------------------
Kubernetes URL : 免填
Certification key: 免填
Kubernetes namespace: jenkinspoc
=> test connection

```

```
#---------------------------------------------
# S4-3. Jenkins URL
#---------------------------------------------
#[syntax] http://<service-name>.<namespace>.svc.cluster.local:8080
Jenkins URL: http://jenkins-service.jenkinspoc.svc.cluster.local:8080
=> SAVE
```

```
#---------------------------------------------
# S4-4. Pod template
#---------------------------------------------
Name: jenkins-agent
namespace: jenkinspoc
Labels: jenkinsagent  <== Job會套用這個Label來找到要用那個Pod配置來建立
Containers:
(如果可以連到DockerHub，可以使用預設的jenkins/inbound-agent)
(以下使用自訂的jnlp，並且覆蓋預設值)
(1) Name: jnlp 
(2) Image: jenkins/inbound-agent:latest
(3) 移除"Sleep" , "99999"   <== 不然會改寫預設的Entrypoint
(4) Service Account : jenkins-admin

```

## 5. Testing: EXEC Specific Job

```
#---------------------------------------------
# S5-1. 建立Job
#---------------------------------------------
Dashboard > New item > name: jenkins-job-1 (free style project) > OK
Label express: jenkinsagent
Build Step > Excute Shell > echo "Test Jenkins JOB Successfully." > SAVE

> Build Now

```

You will find the following:
- new Jenkins agent pod has been created and executing.
- "Buid History" can be accessed, and you can check the "Console Output".

## 6. Testing: EXEC pipeline

```
#---------------------------------------------
# S6-1. 建立Pipeline
#---------------------------------------------
Dashboard > New item > pipeline (name: pipeline-test) > OK

```

```
#---------------------------------------------
# S6-2. Pipeline script
#---------------------------------------------
node('jenkinsagent') {
    stage('Clone') {
      echo "1.Clone Stage"
    }
    stage('Test') {
      echo "2.Test Stage"
    }
    stage('Build') {
      echo "3.Build Stage"
    }
    stage('Deploy') {
      echo "4. Deploy Stage"
    }
}

> SAVE > Build Now

```


