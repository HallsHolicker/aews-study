# AEWS Study
가시다님의 AEWS 스터디에 참여하게 되었습니다.

기본으로 CloudFormation으로 설치를 진행하지만, cloudFormation으로 설치 진행을 하지 않고 Terraform으로 설치를 진행해 보려 합니다.

테라폼 파일에 대한 간단한 설명은 다음과 같습니다.

1. Terraform Directory
  * main.tf      : 기본 설정
  * vpc.tf       : vpc 관련 설정 ( module )
  * ec2.tf       : Bastion Host 설정
  * variable.tf  : 변수 설정
  * output.tf    : 출력 관련 설정
    - bastion Host Public IP
    - EKS Managed Node Group Name
  * data.tf      : 데이터 정보
    - AMI 정보
    - AWS Load Balancer Controller IAM Policy 정보
    - EKS Cluster 정보
    - Domain ACM 정보
  * eks.tf       : eks 설정 ( module )
    - AWS Load Balancer Controller ( Terraform helm 으로 배포 )
  * secret.tf    : AWS Access key, Secret Key 설정 ( 별도 생성 필요 )
  * onoff.tf     : Addon 설치 여부
    - AWS EBS CSI Controller
    - AWS EBS CSI Controller Storage Class GP3
    - AWS EFS CSI Controller
    - Externald DNS
    - Kube-Prometheus-stack
    - Kubecost
    - kapenter
    - keda
  * metrics-server.tf : Metrics Server 설치
  * externaldns.tf : External DNS 설치
  * prometheus.tf : Kube Prometheus Stack 설치 ( kubecost와 동시 설치 안됨)
  * kubecost.tf : kubecost 설치 ( Kube-prometheus-stack하고 동시 설치 안됨 )
  * kapenter.tf : Kapenter 설치
  * keda.tf : keda 설치


2. Test Directory
 * main.tf      : 기본 설정
 * data.tf      : 데이터 정보
   - EKS Cluster 정보
   - Terraform Directory Terraform State 정보
 * test.tf      : AWS Load Balancer Test
   - Echo Server 배포
   - Ingress 설정 ( ALB )
 * onoff.tf     : 테스트 할 배포 스크립트 사용 여부
   - echo-server

secret.tf 정보
```
variable "AWS_AccessKey" {
  default = ""
}

variable "AWS_SecretKey" {
  default = ""
}
```

## Create EKS Cluster

terraform directory에서 실행

```
terraform init
terraform plan
terraform apply --auto-approve
```

## Validation EKS Cluster

우선 Bastion Host에 접속하여 확인합니다.

### EKS Cluster kubeconfig 설정
```
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $CLUSTER_NAME --kubeconfig ~/.kube/config
```

### EKS Cluster 정보 확인
```
kubectl cluster-info
```

>> output
```
Kubernetes control plane is running at https://749EBADAF6DDAE449BD08DAE2E2D6577.gr7.ap-northeast-2.eks.amazonaws.com
CoreDNS is running at https://749EBADAF6DDAE449BD08DAE2E2D6577.gr7.ap-northeast-2.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```
eksctl get cluster
```

>> output
```
NAME		REGION		EKSCTL CREATED
eks_cluster	ap-northeast-2	False
```

```
aws eks describe-cluster --name $CLUSTER_NAME | jq -r .cluster.endpoint
```

>> output
```
https://749EBADAF6DDAE449BD08DAE2E2D6577.gr7.ap-northeast-2.eks.amazonaws.com
```

### EKS Cluster NodeGroup 확인
```
aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name <Terraform output에서 확인 된 EKS_NodeGroup_Name > | jq
```

>> output
```
{
  "nodegroup": {
    "nodegroupName": "eks_cluster-nodegroup-2023050601225039720000000e",
    "nodegroupArn": "arn:aws:eks:ap-northeast-2:472346931973:nodegroup/eks_cluster/eks_cluster-nodegroup-2023050601225039720000000e/90c3f753-c649-228f-55ac-e5e1db4648a0",
    "clusterName": "eks_cluster",
    "version": "1.24",
    "releaseVersion": "1.24.11-20230501",
    "createdAt": "2023-05-06T10:22:54.189000+09:00",
    "modifiedAt": "2023-05-06T10:33:13.483000+09:00",
    "status": "ACTIVE",
    "capacityType": "ON_DEMAND",
    "scalingConfig": {
      "minSize": 2,
      "maxSize": 5,
      "desiredSize": 2
    },
    "instanceTypes": [
      "t3.medium"
    ],
    "subnets": [
      "subnet-04fdc995a7cfa0bda",
      "subnet-01cb9320df319c77c"
    ],
    "amiType": "AL2_x86_64",
    "nodeRole": "arn:aws:iam::472346931973:role/eks_cluster-nodegroup-eks-node-group-20230506011148068700000001",
    "labels": {},
    "resources": {
      "autoScalingGroups": [
        {
          "name": "eks-eks_cluster-nodegroup-2023050601225039720000000e-90c3f753-c649-228f-55ac-e5e1db4648a0"
        }
      ]
    },
    "health": {
      "issues": []
    },
    "updateConfig": {
      "maxUnavailablePercentage": 33
    },
    "launchTemplate": {
      "name": "eks_cluster-nodegroup-2023050601225008250000000c",
      "version": "1",
      "id": "lt-05f1ba0579e624c65"
    },
    "tags": {
      "Name": "eks_cluster-nodegroup"
    }
  }
}
```

### EKS Cluster Node 확인
```
kubectl get node -o wide
```

>> output
```
NAME                                               STATUS   ROLES    AGE   VERSION                INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-192-168-1-51.ap-northeast-2.compute.internal    Ready    <none>   17m   v1.24.11-eks-a59e1f0   192.168.1.51    <none>        Amazon Linux 2   5.10.178-162.673.amzn2.x86_64   containerd://1.6.19
ip-192-168-2-240.ap-northeast-2.compute.internal   Ready    <none>   17m   v1.24.11-eks-a59e1f0   192.168.2.240   <none>        Amazon Linux 2   5.10.178-162.673.amzn2.x86_64   containerd://1.6.19
```

### EKS Cluster Pod 확인
```
kubectl get pod -A
```

>> output
```
NAMESPACE     NAME                                            READY   STATUS    RESTARTS   AGE
kube-system   aws-load-balancer-controller-78fcf94979-6t6kn   1/1     Running   0          13m
kube-system   aws-load-balancer-controller-78fcf94979-kr4sj   1/1     Running   0          13m
kube-system   aws-node-fb6rd                                  1/1     Running   0          11m
kube-system   aws-node-rk4x7                                  1/1     Running   0          11m
kube-system   coredns-dc4979556-bw5gt                         1/1     Running   0          17m
kube-system   coredns-dc4979556-dc89d                         1/1     Running   0          17m
kube-system   kube-proxy-q5698                                1/1     Running   0          11m
kube-system   kube-proxy-qfn9k                                1/1     Running   0          11m
```

------

### AWS Load Balancer Controller TEST

Test Directory에서 실행

```
terraform init
terraform plan
terraform apply --auto-approve
```

bastion host에 접속하여 테스트

POD 확인
```
kubectl get pod -A
```

>> output
```
NAMESPACE     NAME                                            READY   STATUS    RESTARTS   AGE
default       echo-64866f6f-2qfkl                             1/1     Running   0          34s
kube-system   aws-load-balancer-controller-656fb98d4d-jhk5r   1/1     Running   0          12m
kube-system   aws-load-balancer-controller-656fb98d4d-z9stx   1/1     Running   0          12m
kube-system   aws-node-c8gmz                                  1/1     Running   0          13m
kube-system   aws-node-jmjh6                                  1/1     Running   0          13m
kube-system   coredns-dc4979556-7x9rc                         1/1     Running   0          18m
kube-system   coredns-dc4979556-gmsjf                         1/1     Running   0          18m
kube-system   kube-proxy-4bt4l                                1/1     Running   0          13m
kube-system   kube-proxy-5dz5q                                1/1     Running   0          13m
```

```
LB_HOST=$(kubectl get ingress/alb -ojson / jq -r ".status.loadBalancer.ingress[0].hostname")
echo $LB_HOST
```

ALB의 생성에 약 5분 정도 소요 시간 발생

```
curl $LB_HOST
```

>> output
```
Hostname: echo-64866f6f-cxdxp

Pod Information:
	-no pod information available-

Server values:
	server_version=nginx: 1.13.3 - lua: 10008

Request Information:
	client_address=192.168.10.254
	method=GET
	real path=/
	query=
	request_version=1.1
	request_scheme=http
	request_uri=http://k8s-default-alb-b115e9155b-567858982.ap-northeast-2.elb.amazonaws.com:8080/

Request Headers:
	accept=*/*
	host=k8s-default-alb-b115e9155b-567858982.ap-northeast-2.elb.amazonaws.com
	user-agent=curl/7.88.1
	x-amzn-trace-id=Root=1-6455c91d-300c6dfa60232e820b8ec532
	x-forwarded-for=52.79.247.171
	x-forwarded-port=80
	x-forwarded-proto=http

Request Body:
	-no body in request-
```

-------

### AWS EBS CSI Controller Controller TEST

EBS CSI Controller 배포를 위해서 다음 값을 변경

`onoff.tf`
```
variable "ebs_csi_driver" {
  type = bool
  default = "true"  # false => true 로 변경
}

### GP3 Storage Class 배포 필요시
variable "ebs_csi_drivce_sc_gp3" {
  type = bool
  default = "true"   # false => true로 변경     
}

```

#### EBS CSI Controller deploy
```
terraform apply --autoapprove
```

#### EBS CSI Controller depoly validation
```
kubectl get pod -A
```

>> output
```
NAMESPACE     NAME                                            READY   STATUS    RESTARTS   AGE
kube-system   aws-load-balancer-controller-57698b8899-dwhm2   1/1     Running   0          34m
kube-system   aws-load-balancer-controller-57698b8899-vfcsp   1/1     Running   0          34m
kube-system   aws-node-ppz72                                  1/1     Running   0          35m
kube-system   aws-node-w6v28                                  1/1     Running   0          35m
kube-system   coredns-dc4979556-nvhdj                         1/1     Running   0          40m
kube-system   coredns-dc4979556-tgd7q                         1/1     Running   0          40m
kube-system   ebs-csi-controller-7798d49789-8zvsj             5/5     Running   0          20s
kube-system   ebs-csi-controller-7798d49789-k7nrq             5/5     Running   0          20s
kube-system   ebs-csi-node-qghpk                              3/3     Running   0          20s
kube-system   ebs-csi-node-vt8bg                              3/3     Running   0          20s
kube-system   kube-proxy-pwj98                                1/1     Running   0          35m
kube-system   kube-proxy-r62cd                                1/1     Running   0          35m
```

#### EBS CSI Controller GP3 validation
```
kubectl get sc
```

>> output
```
ebs-csi-driver-gp3 (default)   ebs.csi.aws.com         Delete          WaitForFirstConsumer   true                   7s
gp2 (default)                  kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  58m
```

#### PVC 생성

```
cat <<EOT > awsebs-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 4Gi
  storageClassName: gp3
EOT
kubectl apply -f awsebs-pvc.yaml
```

#### PVC 확인

PVC, pod 생성을 terraform으로 하고 싶은 경우 test directory의 onoff.tf의 ebs-test를 true로 하시면 됩니다.

```
kubectl get pvc,pv
```

>> output
```
NAME                              STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/ebs-claim   Pending                                      gp3            16s
```

```
kubectl describe pvc ebs-claim
```

>> output
```
Name:          ebs-claim
Namespace:     default
StorageClass:  gp3
Status:        Pending
Volume:
Labels:        <none>
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                Age               From                         Message
  ----    ------                ----              ----                         -------
  Normal  WaitForFirstConsumer  3s (x3 over 23s)  persistentvolume-controller  waiting for first consumer to be created before binding
```

#### Create test pod

```
cat <<EOT > awsebs-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  terminationGracePeriodSeconds: 3
  containers:
  - name: app
    image: centos
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo \$(date -u) >> /data/out.txt; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: ebs-claim
EOT
kubectl apply -f awsebs-pod.yaml
```

status check

```
kubectl get pvc,pv,pod
```

>> output
```
NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/ebs-claim   Bound    pvc-3e7848b3-cf7a-499b-81c6-94af4cf4b632   4Gi        RWO            gp3            75s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
persistentvolume/pvc-3e7848b3-cf7a-499b-81c6-94af4cf4b632   4Gi        RWO            Delete           Bound    default/ebs-claim   gp3                     25s

NAME      READY   STATUS    RESTARTS   AGE
pod/app   1/1     Running   0          29s
```

```
kubectl get VolumeAttachment
```

>> output
```
NAME                                                                   ATTACHER          PV                                         NODE                                               ATTACHED   AGE
csi-d83951ae3945b175a8b007bf3a05890f2547477dfc7063ffaa3c91b113cf69c4   ebs.csi.aws.com   pvc-3e7848b3-cf7a-499b-81c6-94af4cf4b632   ip-192-168-1-133.ap-northeast-2.compute.internal   true       66s
```

--------

### AWS EFS CSI Controller Controller TEST

EFS CSI Controller 배포를 위해서 다음 값을 변경

`onoff.tf`
```
variable "efs_csi_driver" {
  type = bool
  default = "true"  # false => true 로 변경
}
```

`output.tf`
```
### 주석 제거
output "efs_filesystem_id" {
  value = aws_efs_file_system.aws_efs_csi_driver_efs.0.id
}
```

#### EFS CSI Controller deploy
```
terraform apply --autoapprove
```

#### EFS CSI Controller depoly validation
```
kubectl get pod -A
```

>> output
```
NAMESPACE     NAME                                            READY   STATUS    RESTARTS   AGE
kube-system   aws-load-balancer-controller-57698b8899-dwhm2   1/1     Running   0          156m
kube-system   aws-load-balancer-controller-57698b8899-vfcsp   1/1     Running   0          156m
kube-system   aws-node-ppz72                                  1/1     Running   0          156m
kube-system   aws-node-w6v28                                  1/1     Running   0          156m
kube-system   coredns-dc4979556-nvhdj                         1/1     Running   0          161m
kube-system   coredns-dc4979556-tgd7q                         1/1     Running   0          161m
kube-system   efs-csi-controller-74f8cc67d5-7tcfw             3/3     Running   0          19s
kube-system   efs-csi-controller-74f8cc67d5-p2hsz             3/3     Running   0          19s
kube-system   efs-csi-node-dqkzw                              3/3     Running   0          19s
kube-system   efs-csi-node-lb8md                              3/3     Running   0          19s
kube-system   kube-proxy-pwj98                                1/1     Running   0          156m
kube-system   kube-proxy-r62cd                                1/1     Running   0          156m
```

#### PV 생성

PV, PVC, pod 생성을 terraform으로 하고 싶은 경우 test directory의 onoff.tf의 efs-test를 true로 하시면 됩니다.

```
cat <<EOT > awsefs-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $(aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text)
EOT
kubectl apply -f awsefs-pv.yaml
```

#### PV 확인

```
kubectl get pv
```

>> output
```
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
efs-pv   5Gi        RWX            Retain           Available           efs-sc                  7s
```

```
kubectl describe pv efs-pv
```

>> output
```
Name:            efs-pv
Labels:          <none>
Annotations:     <none>
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    efs-sc
Status:          Available
Claim:
Reclaim Policy:  Retain
Access Modes:    RWX
VolumeMode:      Filesystem
Capacity:        5Gi
Node Affinity:   <none>
Message:
Source:
    Type:              CSI (a Container Storage Interface (CSI) volume source)
    Driver:            efs.csi.aws.com
    FSType:
    VolumeHandle:      fs-0a93221706dc56743
    ReadOnly:          false
    VolumeAttributes:  <none>
Events:                <none>
```

#### PVC 생성

```
cat <<EOT > awsefs-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
EOT
kubectl apply -f awsefs-pvc.yaml
```

#### PVC 확인

```
kubectl get pvc
```

>> output
```
NAME        STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
efs-claim   Bound    efs-pv   5Gi        RWX            efs-sc         53s
```

```
kubectl describe pvc efs-claim
```

>> output
```
Name:          efs-claim
Namespace:     default
StorageClass:  efs-sc
Status:        Bound
Volume:        efs-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
```

#### Create test pod

```
cat <<EOT > awsefs-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app1
spec:
  containers:
  - name: app1
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo \"$(date -u) app1\" >> /data/out.txt; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: efs-claim
---
apiVersion: v1
kind: Pod
metadata:
  name: app2
spec:
  containers:
  - name: app2
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo \"$(date -u) app2\" >> /data/out.txt; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: efs-claim
EOT
kubectl apply -f awsefs-pod.yaml
```

status check

```
kubectl get pvc,pv,pod
```

>> output
```
NAME                              STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/efs-claim   Bound    efs-pv   5Gi        RWX            efs-sc         6m24s

NAME                      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
persistentvolume/efs-pv   5Gi        RWX            Retain           Bound    default/efs-claim   efs-sc                  8m10s

NAME       READY   STATUS    RESTARTS   AGE
pod/app1   1/1     Running   0          7s
pod/app2   1/1     Running   0          7s
```

```
kubectl exec -ti $(kubectl get pod | grep app1 | awk '{print $1}') -- sh -c "tail -n 2 /data/out.txt"
kubectl exec -ti $(kubectl get pod | grep app2 | awk '{print $1}') -- sh -c "tail -n 2 /data/out.txt"
```

>> output ( 같은 값이 보임 )
```
Thu May 11 07:49:09 UTC 2023 app1
Thu May 11 07:49:10 UTC 2023 app2
```


### External DNS validation
```
kubectl get pods -A
```

>> output
```
NAMESPACE        NAME                                            READY   STATUS    RESTARTS   AGE
kube-system      aws-load-balancer-controller-5849cbdfd4-kwj65   1/1     Running   0          150m
kube-system      aws-load-balancer-controller-5849cbdfd4-tf4z4   1/1     Running   0          150m
kube-system      aws-node-lxdsd                                  1/1     Running   0          150m
kube-system      aws-node-t6bff                                  1/1     Running   0          150m
kube-system      coredns-dc4979556-8kffw                         1/1     Running   0          155m
kube-system      coredns-dc4979556-ls8dc                         1/1     Running   0          155m
kube-system      ebs-csi-controller-66d9699557-26s8v             5/5     Running   0          47s
kube-system      ebs-csi-controller-66d9699557-gc24m             5/5     Running   0          47s
kube-system      ebs-csi-node-6rrn2                              3/3     Running   0          47s
kube-system      ebs-csi-node-hkdv8                              3/3     Running   0          47s
kube-system      efs-csi-controller-74f8cc67d5-2mprv             3/3     Running   0          48s
kube-system      efs-csi-controller-74f8cc67d5-5n5lg             3/3     Running   0          48s
kube-system      efs-csi-node-n8r9c                              3/3     Running   0          48s
kube-system      efs-csi-node-xccr7                              3/3     Running   0          48s
>> kube-system      external-dns-6bb6c5fdcf-b6cwj                   1/1     Running   0          49s
kube-system      kube-proxy-kc5t6                                1/1     Running   0          150m
kube-system      kube-proxy-ntfrt                                1/1     Running   0          150m
metrics-server   metrics-server-b6b96bf58-jzvgf                  1/1     Running   0          37m
```

### Kube Prometheus Stack validation
```
kubectl get pod,svc,ingress -n monitoring
```

>> output
```
NAME                                                            READY   STATUS    RESTARTS   AGE
pod/kube-prometheus-stack-grafana-5cf57dd5d7-vhhvs              3/3     Running   0          46s
pod/kube-prometheus-stack-kube-state-metrics-5d6578867c-gnfd4   1/1     Running   0          46s
pod/kube-prometheus-stack-operator-74d474b47b-rtmvs             1/1     Running   0          46s
pod/kube-prometheus-stack-prometheus-node-exporter-gjxbd        1/1     Running   0          46s
pod/kube-prometheus-stack-prometheus-node-exporter-pslnv        1/1     Running   0          46s
pod/prometheus-kube-prometheus-stack-prometheus-0               2/2     Running   0          45s

NAME                                                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kube-prometheus-stack-grafana                    ClusterIP   10.100.168.233   <none>        80/TCP     46s
service/kube-prometheus-stack-kube-state-metrics         ClusterIP   10.100.94.23     <none>        8080/TCP   46s
service/kube-prometheus-stack-operator                   ClusterIP   10.100.30.170    <none>        443/TCP    46s
service/kube-prometheus-stack-prometheus                 ClusterIP   10.100.44.143    <none>        9090/TCP   46s
service/kube-prometheus-stack-prometheus-node-exporter   ClusterIP   10.100.18.23     <none>        9100/TCP   46s
service/prometheus-operated                              ClusterIP   None             <none>        9090/TCP   45s

NAME                                                         CLASS   HOSTS                          ADDRESS                                                        PORTS   AGE
ingress.networking.k8s.io/kube-prometheus-stack-grafana      alb     grafana.hallsholicker.com      myeks-ingress-alb-499438724.ap-northeast-2.elb.amazonaws.com   80      46s
ingress.networking.k8s.io/kube-prometheus-stack-prometheus   alb     prometheus.hallsholicker.com   myeks-ingress-alb-499438724.ap-northeast-2.elb.amazonaws.com   80      46s
```

promehteus는 prometheus.<domain_name> 으로 접속할 수 있습니다.
grafana는 grafana.<domain_name> 으로 접속할 수 있습니다.

### kapenter validation
```
kubectl get pods -A
```

>> output
```
NAMESPACE        NAME                                           READY   STATUS    RESTARTS   AGE
karpenter        karpenter-controller-6975dbf597-j6mcr          1/1     Running   0          38s
karpenter        karpenter-webhook-784bd4c6f4-xp4dl             1/1     Running   0          38s
kube-system      aws-load-balancer-controller-8c8b87bd8-rcpzx   1/1     Running   0          16m
kube-system      aws-load-balancer-controller-8c8b87bd8-z8nps   1/1     Running   0          16m
kube-system      aws-node-9w5rc                                 1/1     Running   0          17m
kube-system      aws-node-c8k2s                                 1/1     Running   0          17m
kube-system      coredns-dc4979556-2479z                        1/1     Running   0          22m
kube-system      coredns-dc4979556-s22z6                        1/1     Running   0          22m
kube-system      kube-proxy-n87kc                               1/1     Running   0          17m
kube-system      kube-proxy-vqr9d                               1/1     Running   0          17m
metrics-server   metrics-server-b6b96bf58-vvnmw                 1/1     Running   0          16m
```

### keda validation
```
kubectl get pods -A
```

>> output
```
NAMESPACE        NAME                                               READY   STATUS    RESTARTS      AGE
keda             keda-admission-webhooks-59978445df-9ljw6           1/1     Running   0             96s
keda             keda-operator-6857fbc758-87wsf                     1/1     Running   1 (84s ago)   96s
keda             keda-operator-metrics-apiserver-765945cb4f-4l4zz   1/1     Running   0             96s
kube-system      aws-load-balancer-controller-8c8b87bd8-rcpzx       1/1     Running   0             27m
kube-system      aws-load-balancer-controller-8c8b87bd8-z8nps       1/1     Running   0             27m
kube-system      aws-node-9w5rc                                     1/1     Running   0             28m
kube-system      aws-node-c8k2s                                     1/1     Running   0             28m
kube-system      coredns-dc4979556-2479z                            1/1     Running   0             33m
kube-system      coredns-dc4979556-s22z6                            1/1     Running   0             33m
kube-system      kube-proxy-n87kc                                   1/1     Running   0             28m
kube-system      kube-proxy-vqr9d                                   1/1     Running   0             28m
metrics-server   metrics-server-b6b96bf58-vvnmw                     1/1     Running   0             27m
```

--------

## Delete EKS Cluster

아래 순서를 지키지 않을 경우 삭제 프로세스가 꼬여서 수동을 삭제 작업을 진행해야 합니다.

#### test directory에서 실행

```
terraform destroy --auto-approve
```

#### terraform directory에서 실행

onoff.tf의 값은 모두 false 로 설정 변경

```
terraform apply --auto-appove
```

#### EKS 삭제

```
terraform destroy --auto-approve
```

# 참조 사이트
- [kakostyle 기술블로그](https://devblog.kakaostyle.com/ko/2022-03-31-3-build-eks-cluster-with-terraform/)
- [headintheclouds](https://blog.devgenius.io/how-to-install-aws-load-balancer-controller-using-terraform-helm-provider-4b4078c69bbf)
- [particuleio github](https://github.com/particuleio/terraform-kubernetes-addons/blob/main/modules/aws/aws-efs-csi-driver.tf)