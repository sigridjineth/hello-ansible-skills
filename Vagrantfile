# Variables

# max number of T nodes
N = 2

# Base Image  https://portal.cloud.hashicorp.com/vagrant/discover/bento/ubuntu-24.04
BOX_IMAGE = "bento/ubuntu-24.04"
BOX_VERSION = "202502.21.0"

Vagrant.configure("2") do |config|
#-Server Node : Ubuntu
    config.vm.define "server" do |subconfig|
      subconfig.vm.box = BOX_IMAGE
      subconfig.vm.box_version = BOX_VERSION
      subconfig.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--groups", "/Ansible-Lab"]
        vb.name = "server"
        vb.cpus = 2
        vb.memory = 1536 # 2048
        vb.linked_clone = true
      end
      subconfig.vm.host_name = "server"
      subconfig.vm.network "private_network", ip: "10.10.1.10"
      subconfig.vm.network "forwarded_port", guest: 22, host: 60000, auto_correct: true, id: "ssh"
      subconfig.vm.synced_folder "./", "/vagrant", disabled: true
      subconfig.vm.provision "shell", path: "init_cfg.sh"
    end

# Test Node : Ubuntu
  (1..N).each do |i|
    config.vm.define "tnode#{i}" do |subconfig|
      subconfig.vm.box = BOX_IMAGE
      subconfig.vm.box_version = BOX_VERSION
      subconfig.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--groups", "/Ansible-Lab"]
        vb.name = "tnode#{i}"
        vb.cpus = 2
        vb.memory = 1536 # 2048
        vb.linked_clone = true
      end
      subconfig.vm.host_name = "tnode#{i}"
      subconfig.vm.network "private_network", ip: "10.10.1.1#{i}"
      subconfig.vm.network "forwarded_port", guest: 22, host: "6000#{i}", auto_correct: true, id: "ssh"
      subconfig.vm.synced_folder "./", "/vagrant", disabled: true
      subconfig.vm.provision "shell", path: "init_cfg.sh", args: [ N ]
    end
  end

# Test Node : Rocky Linux
    config.vm.define "tnode3" do |subconfig|
      subconfig.vm.box = "bento/rockylinux-9"
      subconfig.vm.box_version = "202510.26.0"
      subconfig.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--groups", "/Ansible-Lab"]
        vb.name = "tnode3"
        vb.cpus = 2
        vb.memory = 1536 # 2048
        vb.linked_clone = true
      end
      subconfig.vm.host_name = "tnode3"
      subconfig.vm.network "private_network", ip: "10.10.1.13"
      subconfig.vm.network "forwarded_port", guest: 22, host: 60003, auto_correct: true, id: "ssh"
      subconfig.vm.synced_folder "./", "/vagrant", disabled: true
      subconfig.vm.provision "shell", path: "init_cfg2.sh"
    end

end