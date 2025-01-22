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

# Master 노드에 Join
bash /vagrant/join.sh

