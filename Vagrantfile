# -*- mode: ruby -*-
# vi: set ft=ruby :

MASTER_IP = "192.168.56.10"
NODE_IP_NW = "192.168.56."
NODE_IP_START = 11
NUM_WORKER_NODES = 2

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = false

  # Master Node
  config.vm.define "k8s-master" do |master|
    master.vm.hostname = "k8s-master"
    master.vm.network "private_network", ip: MASTER_IP, virtualbox__intnet: false 
    master.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.name = "k8s-master"
    end
    master.vm.provision "shell", path: "master-node.sh"
  end

  # Worker Nodes
  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "k8s-worker-#{i}" do |worker|
      worker.vm.hostname = "k8s-worker-#{i}"
      worker.vm.network "private_network", ip: "#{NODE_IP_NW}#{NODE_IP_START + i}", virtualbox__intnet: false
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = 8196
        vb.cpus = 4
        vb.name = "k8s-worker-#{i}"
      end
      worker.vm.provision "shell", path: "worker-node.sh"
    end
  end

  # 모든 노드에 대한 공통 설정
  config.vm.provision "shell", inline: <<-SHELL
    # IP 포워딩 활성화
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p

    # iptables 설정
    iptables -P FORWARD ACCEPT
    iptables -A FORWARD -j ACCEPT
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # 필요한 커널 모듈 로드
    modprobe br_netfilter
    echo "br_netfilter" >> /etc/modules

    # 브리지 네트워크 설정
    echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.conf
    sysctl -p
  SHELL
end

