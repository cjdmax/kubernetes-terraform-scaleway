#!/usr/bin/env bash

. ./ips.txt
cat > scw-install.sh << FIN
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -qq \
 && apt-get -qq install apt-transport-https \

# we are installing this one because it is supported by kube-admin, newer CE ones are not (yet?)
apt-get -qq install docker-engine=1.12.6-0~ubuntu-xenial
apt-mark hold docker-engine

echo "DOCKER_OPTS='-H unix:///var/run/docker.sock --storage-driver aufs --label provider=scaleway --mtu=1500 --insecure-registry=10.0.0.0/8'" > /etc/default/docker
systemctl restart docker

apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends kubelet kubeadm kubectl kubernetes-cni \
 && apt-get clean

for arg in "\$@"
do
  case \$arg in
    'master')
      SUID=\$(scw-metadata --cached ID)
      PUBLIC_IP=\$(scw-metadata --cached PUBLIC_IP_ADDRESS)
      PRIVATE_IP=\$(scw-metadata --cached PRIVATE_IP)

      kubeadm --token=\$KUBERNETES_TOKEN --apiserver-advertise-address=\$PUBLIC_IP --service-dns-domain=\$SUID.pub.cloud.scaleway.com init

      KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f http://docs.projectcalico.org/v2.1/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
      git clone -q https://github.com/kubernetes/heapster.git
      KUBECONFIG=/etc/kubernetes/admin.conf kubectl create -f heapster/deploy/kube-config/influxdb/
      KUBECONFIG=/etc/kubernetes/admin.conf kubectl create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
      break
      ;;
    'slave')
      kubeadm join --token \$KUBERNETES_TOKEN $MASTER_00:6443
      break
      ;;
 esac
done
FIN
rm -rf ./ips.txt
