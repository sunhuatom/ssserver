#!/bin/bash
##########################################
# File Name: lasy_setup_ss.sh
# 
##########################################

#----------------------------------------

#check OS version
CHECK_OS_VERSION=`cat /etc/issue |sed -n 1"$1"p|awk '{printf $1}' |tr 'a-z' 'A-Z'`

#list the software need to be installed to the variable FILELIST
UBUNTU_TOOLS_LIBS="python-pip"

CENTOS_TOOLS_LIBS=""

## check whether system is Ubuntu or not
function check_OS_distributor(){
	echo "checking distributor and release ID ..."
	if [[ "${CHECK_OS_VERSION}" == "UBUNTU" ]] ;then
		echo -e "\tCurrent OS: ${CHECK_OS_VERSION}"
		UBUNTU=1
	elif [[ "${CHECK_OS_VERSION}" == "CENTOS" ]] ;then
		echo -e "\tCurrent OS: ${CHECK_OS_VERSION}!!!"
		CENTOS=1
	else
		echo "not support ${CHECK_OS_VERSION} now"
		exit 1
	fi
}

## update system
function update_system()
{
	if [[ ${UNUNTU} -eq 1 ]];then
	{
		echo "apt-get update"
		apt-get update
	}
	elif [[ ${CENTOS} -eq 1 ]];then
	{
		##Webtatic EL6 for CentOS/RHEL 6.x
		rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
		yum install mysql.`uname -i` yum-plugin-replace -y
		yum replace mysql --replace-with mysql55w -y
		yum replace php-common --replace-with=php55w-common -y
	}
	fi
}


#install one software every cycle
function install_soft_for_each(){
	echo "check OS version..."
	check_OS_distributor
	if [[ ${UBUNTU} -eq 1 ]];then
		echo "Will install below software on your Ubuntu system:"
		update_system
		for file in ${UBUNTU_TOOLS_LIBS}
		do
			trap 'echo -e "\ninterrupted by user, exit";exit' INT
			echo "========================="
			echo "installing $file ..."
			echo "-------------------------"
			apt-get install $file -y
			sleep 1
			echo "$file installed ."
		done
		pip install shadowsocks

	elif [[ ${CENTOS} -eq 1 ]];then
		echo "Will install softwears on your CentOs system:"
		update_system
		for file in ${CENTOS_TOOLS_LIBS}
		do
			trap 'echo -e "\ninterrupted by user, exit";exit' INT
			echo "========================="
			echo "installing $file ..."
			echo "-------------------------"
			yum install $file -y
			sleep 3
			echo "$file installed ."
		done
		easy_install pip
		pip install shadowsocks

	else
		echo "Other OS not support yet, please try Ubuntu or CentOs"
		exit 1
	fi
}


#start shadowsocks server
function start_ss()
{


	cp shadowsocks.json /etc/shadowsocks.json

	#add start-up
	cp ssserver.service /etc/systemd/system/ssserver.service
	systemctl enable ssserver
	#start ssserver service
	systemctl start ssserver
	# optimize shadowsocks
	OPTI=local.conf
	LOCALCONF=/etc/sysctl.d/local.conf
	cat "$OPTI" >> "$LOCALCONF"
	nohup sysctl --system
	#nofile limit
	echo "root - nofile 16384" >> /etc/security/limits.conf
	####
	echo ""
	echo "========================================================================e"
	echo "congratulations, shadowsocks server starting..."
	echo "========================================================================"
	echo "The log file is in /var/log/shadowsocks.log..."
	echo "========================================================================"
}

#====================
# main
#
#judge whether root or not
if [ "$EUID" -eq 0 ];then
	install_soft_for_each
	start_ss
else
	echo -e "please run it as root user again !!!\n"
	exit 1
fi
