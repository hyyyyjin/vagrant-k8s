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
    master.vm.network "private_network", ip: MASTER_IP
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
      worker.vm.network "private_network", ip: "#{NODE_IP_NW}#{NODE_IP_START + i}"
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = 1024
        vb.cpus = 1
        vb.name = "k8s-worker-#{i}"
      end
      worker.vm.provision "shell", path: "worker-node.sh"
    end
  end
end

