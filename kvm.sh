#!/bin/bash
create_multi_host(){
	read -p "输入新虚拟机名字: " create_all_name
	read -p "输入虚拟机的数量: " num
	for((i=1;i<=$num;i++))
	do
		qemu-img create -f qcow2 -b /kvm/centos7u6-template.img /kvm/${create_all_name}-${i}.img
		cp /etc/libvirt/qemu/centos7u6-template.xml /etc/libvirt/qemu/${create_all_name}-${i}.xml
		sed -i "s/centos7u6-template/$cteate_all_name-${i}/" /etc/libvirt/qemu/${create_all_name}-${i}.xml
		sed -i /uuid/d /etc/libvirt/qemu/${create_all_name}-${i}.xml
		sed -i /'mac '/d /etc/libvirt/qemu/${create_all_name}-${i}.xml
		virsh define /etc/libvirt/qemu/${create_all_name}-${i}.xml
	done
}

create_one_host(){
	read -p "输入新虚拟机名字: " name
		qemu-img create -f qcow2 -b /kvm/centos7u6-template.img /kvm/${name}.img
		cp /etc/libvirt/qemu/centos7u6-template.xml /etc/libvirt/qemu/${name}.xml
		sed -i "s/centos7u6-template/$name/" /etc/libvirt/qemu/${name}.xml
		sed -i /uuid/d /etc/libvirt/qemu/${name}.xml
		sed -i /'mac '/d /etc/libvirt/qemu/${name}.xml
		virsh define /etc/libvirt/qemu/${name}.xml
	
}

query_all_host(){
	:
}

start_all_host(){
	
	echo '您当前虚拟机的状态'
	virsh list --all
	read -p "确定要启动全部虚拟机？[yes/no]" choice_start
		if [ $choice_start == yes ]
		then
			ary=($(virsh list --all | awk '{print $2}' | sed "/^$/d" | sed "/centos7u6-template/d" | sed "/名称/d"))
			ary_sum=${#ary[@]}
			for i in ${ary[@]}
			do
				virsh start $i
	
			done
		elif [ $choice_start == no ]
		then
			echo "已取消启动全部"
		else
			echo "您的输入有误，请重新选择"
		fi
}

start_group_host(){
	echo '您当前虚拟机的状态'
	virsh list --all
	read -p "请输入要启动的一组虚拟机" create_group_host
	for i in ${create_group_host[@]}
	do
		virsh start $i
	done
}
start_one_host(){
	
	echo '您当前虚拟机的状态'
        virsh list --all
	read -p "请输入要启动的虚拟机的名字" create_name
	virsh start $create_name
}

stop_all_host(){
	echo '您当前虚拟机的状态'
        virsh list --all
        read -p "确定要关闭全部虚拟机？[yes/no]" choice_stop
                if [ $choice_stop == yes ]
                then    
                        stop_ary=($(virsh list --all | awk '{print $2}' | sed "/^$/d" | sed "/centos7u6-template/d" | sed "/名称/d"))
                        stop_ary_sum=${#ary[@]}
                        for i in ${stop_ary[@]}
                        do      
                                virsh destroy $i
                        
                        done
                elif [ $stop_choice == no ]
                then    
                        echo "已取消关闭全部"
                else    
                        echo "您的输入有误，请重新选择"
                fi
}

stop_one_host(){
	echo '您当前虚拟机的状态'
        virsh list --all
        read -p "请输入要关闭的虚拟机的名字" stop_name
        virsh destroy $stop_name
}

remove_all_host(){
	echo '您当前虚拟机的状态'
        virsh list --all
        read -p "确定要删除全部虚拟机？[yes/no]" remove_choice
                if [ $remove_choice == yes ]
                then    
                        remove_ary=($(virsh list --all | awk '{print $2}' | sed "/^$/d" | sed "/centos7u6-template/d" | sed "/名称/d"))
                        remove_ary_sum=${#ary[@]}
                        for i in ${remove_ary[@]}
                        do      
                                virsh undefine $i
                        
                        done
                elif [ $remove_choice == no ]
                then    
                        echo "已取消删除全部"
                else    
                        echo "您的输入有误，请重新选择"
                fi
}

remove_one_host(){
	echo '您当前虚拟机的状态'
        virsh list --all
        read -p "请输入要删除的虚拟机的名字" remove_name
        virsh undefine $remove_name	
}

modify_one_kvm(){
	read -p '请输入要配置的虚拟机' modify_host
	umount /mnt
	rm -rf /mnt/*
	guestmount -a /kvm/$modify_host.img -i /mnt/
	echo '初始化网络' 
	read -p '请输入IP:' IP
	read -p '请输入网关(GATEWAY):' GATEWAY
	read -p '请输入掩码(NETMASK):' NETMASK
	read -p '请输入DNS:' DNS
	cat  > /mnt/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
TYPE="Ethernet"
BOOTPROTO="none"
NAME="eth0"
DEVICE="eth0"
ONBOOT="yes"
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
DNS1=$DNS
EOF
	echo '初始化主机名'
	read -p '请输入要设置的主机名' hostname
	hostname_ip=$(cat /mnt/etc/sysconfig/network-scripts/ifcfg-eth0 | grep IPADDR | awk -F'=' '{print $2}')
	echo $hostname_ip $hostname >> /mnt/etc/hosts
	echo hostnamectl set-hostname $hostname >> /mnt/etc/rc.local
	echo "设置成功IP为$IP,主机名为$hostname"
}

modify_all_kvm(){
	read -p '请输入要配置的虚拟机名' modify_all_host
	read -p '请输入要配置的虚拟机数量' modify_all_sum
	read -p '请输入IP:' modify_all_IP
        read -p '请输入网关(GATEWAY):' modify_all_GATEWAY
        read -p '请输入掩码(NETMASK):' modify_all_NETMASK
        read -p '请输入DNS:' modify_all_DNS
	echo '初始化主机名'
        read -p '请输入要设置的主机名' modify_all_hostname
	ip_sum=`awk -F'.' '/IPADDR/{print $4}' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0`
	for ((i=1;i<=$modify_all_sum;i++))
	do
	umount /mnt
        rm -rf /mnt/* 
        guestmount -a /kvm/$modify_all_host-$i.img -i /mnt/
	ip_sum2=$(($ip_sum+$i))
	cat  > /mnt/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
TYPE="Ethernet"
BOOTPROTO="none"
NAME="eth0"
DEVICE="eth0"
ONBOOT="yes"
IPADDR=$modify_all_IP
NETMASK=$modify_all_NETMASK
GATEWAY=$modify_all_GATEWAY
DNS1=$modify_all_DNS
EOF
	cat /mnt/etc/sysconfig/network-scripts/ifcfg-eth0 | grep IPADDR | awk -F'.' '{print $4}' | sed -i "s/$ip_sum/$ip_sum2/" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	echo "配置成功IP地址为$modify_all_IP"
        hostname_all_ip=$(cat /mnt/etc/sysconfig/network-scripts/ifcfg-eth0 | grep IPADDR | awk -F'=' '{print $2}')
        echo $hostname_all_ip $modify_all_hostname >> /mnt/etc/hosts
        echo hostnamectl set-hostname $modify_all_hostname >> /mnt/etc/rc.local
	echo "配置成功主机名为$modify_all_hostname"
	done
}
add_disk(){
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	echo '您当前虚拟机的状态:'
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	virsh list --all
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	read -p '请输入要添加磁盘的虚拟机:' add_disk_host
	read -p '请输入要添加磁盘的大小:' add_disk_size
	read -p '请输入要添加磁盘的名称:' add_disk_name
	qemu-img create -f qcow2 /kvm/$add_disk_host.img $add_disk_size
	virsh attach-disk $add_disk_host --source /kvm/$add_disk_host.img --target $add_disk_name --cache writeback --subdriver qcow2 --persistent
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	echo '当前磁盘状态:'
	virsh domblklist $add_disk_host
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
}
delect_disk(){
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	echo '您当前虚拟机的状态:'
	virsh list --all
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	echo '当前磁盘状态:'
	virsh domblklist $add_disk_host
	echo '♥♥♥♥♥♥♥♥♥♥♥♥'
	echo '当前磁盘状态:'
	virsh domblklist $add_disk_host
	read -p '请输入要删除磁盘的虚拟机:' delect_disk_host
	read -p '请输入要删除磁盘的名称:' delect_disk_name
	virsh datach--disk $delect_disk_host $delect_disk_name --persistent
	echo '当前磁盘状态:'
	virsh domblklist $add_disk_host
}
add_network(){
	echo '您当前虚拟机的状态:'
        virsh list --all
	read -p "请输入要添加网卡的主机名" add_network_host
	virsh attach-interface $add_network_host --type bridge --source virbr0 --persistent

}
menu="
1.创建虚拟机
2.查询虚拟机
3.启动虚拟机
4.关闭虚拟机
5.删除虚拟机
6.修改虚拟机配置
7.添加硬盘
8.添加网卡
9.退出脚本
请选择您的操作[1|2|3|4|5|6|7|8|9]: "
while true
do
	read -p "$menu" number
	case $number in
	1)
		create_menu="
		1.创建多个虚拟机
		2.创建单个虚拟机
		3.返回上一层
		请选择您的操作[1|2|3]:"
		while true
		do
			read -p "$create_menu" create_number
			case $create_number in
			1)
			create_multi_host
			;;
			2)
			create_one_host
			;;
			3)
				break
			;;
			*)
			echo "您的输入有误请重新输入"
			;;
			esac
		done
	;;
	2)
		virsh list --all
	;;
	3)
		echo "您当前虚拟机的状态"
		virsh list --all
		start_menu="
		1.启动多个虚拟机
		2.启动单个虚拟机
		3.启动一组虚拟机(以空格作为分隔符):
		4.返回上一层
		请选择您的操作[1|2|3]:"
		while true
                do
                        read -p "$start_menu" start_number
                        case $start_number in
                        1)
			start_all_host
                        ;;
                        2)
                        start_one_host
                        ;;
			3)
			start_group_host
			;;
                        4)
                        break
                        ;;      
                        *)
                        echo "您的输入有误请重新输入"
                        ;;
                        esac
		done
	;;
	4)	
		echo "您当前虚拟机的状态"
                virsh list --all
                stop_menu="
                1.关闭多个虚拟机
                2.关闭单个虚拟机
                3.返回上一层
                请选择您的操作[1|2|3]:"
                while true
                do
                        read -p "$stop_menu" stop_number
                        case $stop_number in
                        1)
                        stop_all_host
                        ;;
                        2)
                        stop_one_host
                        ;;
                        3)
                        break
                        ;;
                        *)
                        echo "您的输入有误请重新输入"
                        ;;
                        esac
                done
	;;
	5)
		echo "您当前虚拟机的状态"
                virsh list --all
                remove_menu="
                1.删除多个虚拟机
                2.删除单个虚拟机
                3.返回上一层
                请选择您的操作[1|2|3]:"
                while true
                do
                        read -p "$remove_menu" remove_number
                        case $remove_number in
                        1)
                        remove_all_host
                        ;;
                        2)
                        remove_one_host
                        ;;
                        3)
                        break
                        ;;
                        *)
                        echo "您的输入有误请重新输入"
                        ;;
                        esac
                done
	;;
	6)
echo "您当前虚拟机的状态"
virsh list --all
modify_menu="
1.配置多个虚拟机 
2.配置单个虚拟机
3.返回上一层
请选择您的操作[1|2|3]:"
while true
do
	read -p "$modify_menu" modify_number
        case $modify_number in
1)
modify_all_kvm
;;
2)
modify_one_kvm
;;
3)
break
;;
*)
echo "您的输入有误请重新输入"
;;
esac
done
	;;
	7)
modify_disk="
1.添加网卡
2.删除网卡
3.返回上一层
请选择您的操作[1|2|3]:"
while true
do
        read -p "$modify_disk" modify_number
        case $modify_number in
        1)
	add_disk
        ;;
        2)
	delect_disk
        ;;
        3)
        break
        ;;
        *)
        echo "您的输入有误请重新输入"
        ;;
        esac
done

	;;
	8)
		add_network
	;;
	9)
		break
	;;
	*)
		echo "选择正确的操作"
	;;
	esac
done
