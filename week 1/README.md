# AEWS Study
가시다님의 AEWS 스터디에 참여하게 되었습니다.

1주차로 Amazon EKS 설치에 대해서 스터디를 진행하였으며, 기본으로 CloudFormation으로 설치를 진행하였습니다.

저는 CLoudFormation으로 설치 진행을 하지 않고 Terraform으로 설치를 진행해 보려 합니다.

1주차에는 module을 사용하지 않고 terraform을 작성하겠습니다.

테라폼 파일에 대한 간단한 설명은 다음과 같습니다.

 * main.tf      : 기본 설정
 * vpc.tf       : vpc 관련 설정
 * ec2.tf       : Bastion Host 설정
 * variable.tf  : 변수 설정
 * output.tf    : 출력 관련 설정
   - bastion Host Public IP
 * data.tf      : 데이터 정보 설정
 * eks.tf       : eks 설정
 * secret.tf    : AWS Access key, Secret Key 설정 ( 별도 생성 필요 )

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

```
terraform init
terraform plan
terraform apply --auto-approve
```

## Validation EKS Cluster

우선 Bastion Host에 접속하여 확인합니다.

### EKS Cluster kubeconfig 설정
```
aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $CLUSTER_NAME --kubeconfig ~/.kube/eks_cluster
```

### EKS Cluster 정보 확인
```
kubectl cluster-info
```

>> output
```
Kubernetes control plane is running at https://D772B69F31709C3E02873D34DF9BA349.sk1.ap-northeast-2.eks.amazonaws.com
CoreDNS is running at https://D772B69F31709C3E02873D34DF9BA349.sk1.ap-northeast-2.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
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
https://D772B69F31709C3E02873D34DF9BA349.sk1.ap-northeast-2.eks.amazonaws.com
```

### EKS Cluster NodeGroup 확인
```
aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $CLUSTER_NAME-nodegroup | jq
```

>> output
```
{
  "nodegroup": {
    "nodegroupName": "eks_cluster-nodegroup",
    "nodegroupArn": "arn:aws:eks:ap-northeast-2:472346931973:nodegroup/eks_cluster/eks_cluster-nodegroup/ccc3e19e-0761-ca14-53b9-9edc085ef86e",
    "clusterName": "eks_cluster",
    "version": "1.24",
    "releaseVersion": "1.24.11-20230411",
    "createdAt": "2023-04-28T00:01:48.589000+09:00",
    "modifiedAt": "2023-04-28T00:06:38.674000+09:00",
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
      "subnet-01f9d6291997d5f84",
      "subnet-04cf61767103d2a62"
    ],
    "remoteAccess": {
      "ec2SshKey": "study-aws",
      "sourceSecurityGroups": [
        "sg-04a5f794a1541b9e1"
      ]
    },
    "amiType": "AL2_x86_64",
    "nodeRole": "arn:aws:iam::472346931973:role/eks_nodegroup_role",
    "labels": {},
    "resources": {
      "autoScalingGroups": [
        {
          "name": "eks-eks_cluster-nodegroup-ccc3e19e-0761-ca14-53b9-9edc085ef86e"
        }
      ],
      "remoteAccessSecurityGroup": "sg-01677874c30a0df87"
    },
    "diskSize": 30,
    "health": {
      "issues": []
    },
    "updateConfig": {
      "maxUnavailable": 1
    },
    "tags": {
      "Name": "eks_cluster_node"
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
NAME                                              STATUS   ROLES    AGE     VERSION                INTERNAL-IP    EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-192-168-1-35.ap-northeast-2.compute.internal   Ready    <none>   6m5s    v1.24.11-eks-a59e1f0   192.168.1.35   <none>        Amazon Linux 2   5.10.176-157.645.amzn2.x86_64   containerd://1.6.19
ip-192-168-2-85.ap-northeast-2.compute.internal   Ready    <none>   6m12s   v1.24.11-eks-a59e1f0   192.168.2.85   <none>        Amazon Linux 2   5.10.176-157.645.amzn2.x86_64   containerd://1.6.19
```

### EKS Cluster Pod 확인
```
kubectl get pod -A
```

>> output
```
NAMESPACE     NAME                      READY   STATUS    RESTARTS   AGE
kube-system   aws-node-4wlpm            1/1     Running   0          6m43s
kube-system   aws-node-zwxzz            1/1     Running   0          6m36s
kube-system   coredns-dc4979556-5vpn6   1/1     Running   0          14m
kube-system   coredns-dc4979556-h8zg2   1/1     Running   0          14m
kube-system   kube-proxy-95795          1/1     Running   0          6m36s
kube-system   kube-proxy-x4zrk          1/1     Running   0          6m43s
```


## Delete EKS Cluster

```
terraform destroy --auto-approve
```