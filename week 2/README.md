# AEWS Study
가시다님의 AEWS 스터디에 참여하게 되었습니다.

1주차로 Amazon EKS 설치에 대해서 스터디를 진행하였으며, 기본으로 CloudFormation으로 설치를 진행하였습니다.

저는 CLoudFormation으로 설치 진행을 하지 않고 Terraform으로 설치를 진행해 보려 합니다.

2주차에서는 vpc와 eks는 모듈을 사용하여 배포해 보겠습니다.

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
  * eks.tf       : eks 설정 ( module )
    - AWS Load Balancer Controller ( Terraform helm 으로 배포 )
  * secret.tf    : AWS Access key, Secret Key 설정 ( 별도 생성 필요 )


2. Test Directory
 * main.tf      : 기본 설정
 * data.tf      : 데이터 정보
   - EKS Cluster 정보
   - Terraform Directory Terraform State 정보
 * test.tf      : AWS Load Balancer Test
   - Echo Server 배포
   - Ingress 설정 ( ALB )

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

## Delete EKS Cluster

아래 순서를 지키지 않을 경우 삭제 프로세스가 꼬여서 수동을 삭제 작업을 진행해야 합니다.

test directory에서 실행

```
terraform destroy --auto-approve
```

terraform directory에서 실행

```
terraform destroy --auto-approve
```

# 참조 사이트
- [kakostyle 기술블로그](https://devblog.kakaostyle.com/ko/2022-03-31-3-build-eks-cluster-with-terraform/)
- [headintheclouds](https://blog.devgenius.io/how-to-install-aws-load-balancer-controller-using-terraform-helm-provider-4b4078c69bbf)