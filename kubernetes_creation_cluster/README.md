# Kubernetes cluster
### Skills summary:
- **#bash**
- **#ansible**
- **#terraform**
- **#kubernetes**
---
### I. Cluster Creation
Before cluster creation in AWS, create **ssh key** to access nodes.
``` sh
> cd terraform_cluster_installation
> terraform init
> terraform plan
> terraform apply
```
Output:
```
private-masters-ip = [
  "172.31.34.40",
  "172.31.41.112",
  "172.31.46.155",
]
private-nodes-ip = [
  "172.31.33.248",
  "172.31.47.71",
  "172.31.40.193",
]
public-masters-ip = [
  "3.9.191.204",
  "3.11.81.227",
  "35.176.153.247",
]
public-nodes-ip = [
  "3.8.162.46",
  "3.8.95.243",
  "35.178.182.21",
]
```
---
### II. Kubernetes Installation
Disable on nodes:
1. SELinux
2. Swap.
3. FirewallD

Clone kubespray repository:
```
> git clone https://github.com/kubernetes-sigs/kubespray.git
> cd kubespray
> pip install -r requirements.txt
```
Edit files:
- **`/kubernetes_cluster_inventory/group_vars/all/all.yml`**
    ```
    kubelet_load_modules: true # load modules without admin
    kube_read_only_port: 10255 # port for monitoring
    ```

- **`/kubernetes_cluster_inventory/group_vars/all/docker.yml`**:
    ```
    docker_storage_options: -s overlay2 # overlay2 for docker
    ```
- **`/kubernetes_cluster_inventory/group_vars/etcd.yml`**
    ```
    etcd_memory_limit: 0 # disable memory limit
    ```
- **`/kubernetes_cluster_inventory/group_vars/k8s-cluster/k8s-cluster.yml`**
    ```
    kube_network_plugin: flannel
    kube_proxy_mode: iptables
    kubeconfig_localhost: true #
    ```
- **`/kubernetes_cluster_inventory/group_vars/k8s-cluster/k8s-net-flannel.yml`**
    ```
    flannel_interface_regexp: '172\\.31\\.\\d{1,3}' # 192.168.55.0 => 192\\.168\\.55\\.\\d{1,3}
    flannel_backend_type: "host-gw"
    ```

Run ansible playbook:
```
> ansible-playbook -v -i kubernetes_cluster_inventory/hosts.ini kubespray/cluster.yml -u centos --private-key=~/.ssh/aws.pem -b
> ansible-playbook -v -i kubernetes_cluster_inventory/hosts.ini kubespray/scale.yml -u centos --private-key=~/.ssh/aws.pem -b
> ansible-playbook -v -i kubernetes_cluster_inventory/hosts.ini kubespray/remove-node.yml -u centos --private-key=~/.ssh/jenkins_aws.pem -b --extra-vars "node=kubworker-2,kubworker-3"
```
---
### III. Kubernetes Cluster Management

Connect to the **master node**:
```
> ssh -i /var/lib/jenkins/.ssh/jenkins_aws.pem centos@3.9.191.204
> sudo cp /etc/kubernetes/admin.conf $HOME/
> sudo chown $(id -u):$(id -g) $HOME/admin.conf
> export KUBECONFIG=$HOME/admin.conf
```

Rename labels for cluster nodes:
```
> kubectl get nodes
> kubectl label node sys-kubworker-1 node-role.kubernetes.io/node=
> kubectl label node sys-kubworker-2 node-role.kubernetes.io/node=
> kubectl label node sys-kubworker-3 node-role.kubernetes.io/node=
> kubectl get node
> kubectl cluster-info
```

Configure to use default namespace **development**:
```
> kubectl config set-context --current --namespace=development
> kubectl config view | grep namespace
> kubectl config view
```

**Dasboard installation**:
```
> kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc5/aio/deploy/recommended.yaml
> kubectl get po -n kubernetes-dashboard -o wide
> kubectl get po -n kube-system -o wide
> kubectl get po -n kubernetes-dashboard -o wide
> kubectl get svc -n kubernetes-dashboard -o wide
> kubectl edit svc kubernetes-dashboard -n kubernetes-dashboard
> kubectl describe po kubernetes-dashboard-866f987876-nc9xc -n kubernetes-dashboard
> kubectl get svc -n kubernetes-dashboard -o wide
> kubectl create -f users/axys_admin_user.yaml 
> kubectl get secrets -n kube-system
> kubectl get secrets -n kube-system | grep sys
> kubectl describe secret sys-admin-token-bm6zc -n kube-system
```

**Install HELM 3**:
```
> curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
> helm ls
> helm list
> helm delete test
```

**Fix issue with flannel network**:
```
> kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml
```
 
 **Configure monitoring**:
 ```
https://github.com/coreos/kube-prometheus
http://ec2-3-8-162-46.eu-west-2.compute.amazonaws.com:31527/gameConfig?gameCode=6&username=sadmin&providerId=48&operatorId=1&currency=GBP&sessionToken=213qewfw345asdfq34

> helm repo add elastic https://helm.elastic.co
> helm install elasticsearch elastic/elasticsearch --set service.type=LoadBalancer --set resources.requests.memory=1Gi --set replicas=2 --namespace logging
> helm install filebeat elastic/filebeat --namespace logging
> helm install kibana elastic/kibana --set service.type=LoadBalancer --namespace logging
> sudo chown -R 1000:1000 /usr/share/elasticsearch/data/nodes/
 ```

**Kubernetes docker login to registry**:
Copy certificate into all kubernetes nodes
```
> /etc/pki/ca-trust/source/anchors/game.com-fullchain.crt
> sudo update-ca-trust
> sudo /bin/systemctl restart docker.service
> sudo docker login harbor.com
> kubectl create secret docker-registry regcred --docker-server=https://harbor.com/ --docker-username=USER --docker-password=PASSWORD
```
**Kubernetes labels**:
```
> kubectl label nodes sys-kubworker-1 podtype-
> kubectl label nodes sys-kubworker-2 app.kubernetes.io/component=game-service
> kubectl label nodes sys-kubworker-3 app.kubernetes.io/component=game-service
> kubectl label nodes sys-kubworker-2 app.kubernetes.io/name=gameconfig
> kubectl label nodes sys-kubworker-3 app.kubernetes.io/name=gameconfig
> kubectl label nodes sys-kubworker-1 app.kubernetes.io/name=ingress-nginx
```

**Install ingress**:
```
helm install test nginx-stable/nginx-ingress --set controller.nodeSelector."app\.kubernetes\.io/name"=ingress
helm install stage nginx-stable/nginx-ingress --set controller.nodeSelector."app\.kubernetes\.io/name"=ingress
"worker-connections": "16384"
```
