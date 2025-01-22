#!/bin/bash

# 시스템 업데이트 및 기본 패키지 설치
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Docker 설치
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Docker 데몬 설정
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl restart docker

# Kubernetes 새로운 repo 키 및 저장소 추가
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Kubernetes 컴포넌트 설치
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# swap 비활성화
swapoff -a
sed -i '/swap/d' /etc/fstab

# 필요한 모듈 로드
modprobe br_netfilter
modprobe overlay

# 시스템 설정
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Master 노드 초기화
kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=all > /root/kubeadm-init.output

# kubeconfig 설정
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# root 사용자를 위한 kubeconfig 설정
export KUBECONFIG=/etc/kubernetes/admin.conf

# Calico Operator 설치
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml

# CRD가 완전히 생성될 때까지 대기
echo "Waiting for Calico CRDs to be ready..."
sleep 30

# Installation CR 생성
cat <<EOF | kubectl create -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: None
      natOutgoing: "Enabled"
      nodeSelector: all()
EOF

# Calico pods가 실행될 때까지 대기
echo "Waiting for Calico pods to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n calico-system --timeout=90s

# kube-proxy iptables 모드 설정
kubectl -n kube-system get configmap kube-proxy -o yaml | sed 's/mode: ""/mode: "iptables"/' | kubectl replace -f -
kubectl -n kube-system delete pod -l k8s-app=kube-proxy

# Join 커맨드 저장
cat /root/kubeadm-init.output | grep -A 2 "kubeadm join" > /vagrant/join.sh
chmod +x /vagrant/join.sh

