#!/usr/bin/env bash

echo ">>>> Initial Config Start <<<<"

echo "[TASK 1] Setting Profile & Change Timezone"
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> /home/vagrant/.bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

echo "[TASK 2] Disable firewalld and selinux"
systemctl stop firewalld && systemctl disable firewalld  >/dev/null 2>&1
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "[TASK 5] Install Packages"
dnf install -y yum sshpass jq git >/dev/null 2>&1

echo "[TASK 4] Config account & ssh config"
echo 'vagrant:qwe123' | chpasswd
echo 'root:qwe123' | chpasswd
sed -i "s/^#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd

echo "[TASK 5] Setting Local DNS Using Hosts file"
sed -i '/^127\.0\.\(1\|2\)\.1/d' /etc/hosts
cat << EOF >> /etc/hosts
10.10.1.10 server
10.10.1.11 tnode1
10.10.1.12 tnode2
10.10.1.13 tnode3
EOF

echo ">>>> Initial Config End <<<<"
