#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS 6,7, Debian, Ubuntu                  #
#   Description: One click Install ShadowsocksR Server            #
#   Author: 91yun <https://twitter.com/91yun>                     #
#   Thanks: @breakwa11 <https://twitter.com/breakwa11>            #
#   Thanks: @Teddysun <i@teddysun.com>                            #
#=================================================================#

clear
clear
echo -e "\033[34m================================================================\033[0m

\033[31m                欢迎使用SSR一键脚本                         \033[0m


\033[31m                  即将开始搭建...                   \033[0m
\033[34m================================================================\033[0m";
echo

echo

#Current folder
cur_dir=`pwd`
# Get public IP address
IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1)
if [[ "$IP" = "" ]]; then
    IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
fi

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "错误：请在root用户下执行此脚本！" 1>&2
       exit 1
    fi
}

# Check OS
function checkos(){
    if [ -f /etc/redhat-release ];then
        OS='CentOS'
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS='Debian'
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS='Ubuntu'
    else
        echo "不支持该系统版本，请更换系统后再试！"
        exit 1
    fi
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}

# Disable selinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

# Pre-installation settings
function pre_install(){
    # Not support CentOS 5
    if centosversion 5; then
        echo "不支持CentOS 5, 请更换CentOS 6+/Debian 7+/Ubuntu 12+ 然后再试！"
        exit 1
    fi
    echo "完成以下密码/端口设置开始 SSR 安装!"
    echo -e "请输入SSR连接密码:"
    read -p "(默认密码: admin0000):" shadowsockspwd
    [ -z "$shadowsockspwd" ] && shadowsockspwd="admin0000"
    echo
    echo "---------------------------"
    echo "密码 = $shadowsockspwd"
    echo "---------------------------"
    echo
    # Set ShadowsocksR config port
    while true
    do
    echo -e "请输入SSR连接端口,不设置将默认8080端口:"
    read -p "(默认自动设置SSR端口为8080):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport="8080"
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo
            echo "---------------------------"
            echo "端口 = $shadowsocksport"
            echo "---------------------------"
            echo
            break
        else
            echo "输入错误，请输入1-65535之间的数字！"
        fi
    else
        echo "输入错误，请输入1-65535之间的数字！"
    fi
    done
	
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo
    echo "请按下回车键继续或按 Ctrl+C 退出"
    char=`get_char`
    # Install necessary dependencies
    echo "正在完成基本库安装....."
    
    if [ "$OS" == 'CentOS' ]; then
        yum install -y wget unzip openssl-devel gcc swig python python-devel python-setuptools autoconf libtool libevent git ntpdate
        yum install -y m2crypto automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
    else
        apt-get -y update
        apt-get -y install python python-dev python-pip python-m2crypto curl wget unzip gcc swig automake make perl cpio build-essential git ntpdate
    fi
    cd $cur_dir
}
   echo "成基本库安装完成！"
# Download files
function download_files(){
    # Download libsodium file
        echo "正在下载 libsodium 文件！"
    if ! wget --no-check-certificate -O libsodium-1.0.12.tar.gz https://github.com/luvis12/shadowsocksR/raw/master/libsodium-1.0.12.tar.gz.gz; then
        echo " libsodium 文件下载失败！"
        exit 1
    fi
    # Download ShadowsocksR file
    # if ! wget --no-check-certificate -O manyuser.zip https://github.com/breakwa11/shadowsocks/archive/manyuser.zip; then
        # echo "Failed to download ShadowsocksR file!"
        # exit 1
    # fi
    # Download ShadowsocksR chkconfig file
    echo "正在下载 ShadowsocksR chkconfig file！"
    if [ "$OS" == 'CentOS' ]; then
        if ! wget --no-check-certificate https://raw.githubusercontent.com/luvis12/shadowsocksR/master/shadowsocksR -O /etc/init.d/shadowsocks; then
            echo " ShadowsocksR chkconfig file下载失败！ "
            exit 1
        fi
    else
        if ! wget --no-check-certificate https://raw.githubusercontent.com/luvis12/shadowsocksR/master/shadowsocksR-debian -O /etc/init.d/shadowsocks; then
            echo " ShadowsocksR chkconfig file下载失败！ "
            exit 1
        fi
    fi
}

# firewall set
   echo "正在设置防火墙..."
function firewall_set(){
        if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep '${shadowsocksport}' | grep 'ACCEPT' > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksport} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo "端口 ${shadowsocksport} 已成功开通！"
            fi
        else
            echo "WARNING: 防火墙已关闭或未安装, 请手动安装！"
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ];then
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
            firewall-cmd --reload
        else
			/etc/init.d/iptables status > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				iptables -L -n | grep '${shadowsocksport}' | grep 'ACCEPT' > /dev/null 2>&1
				if [ $? -ne 0 ]; then
					iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
					iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksport} -j ACCEPT
					/etc/init.d/iptables save
					/etc/init.d/iptables restart
				else
					echo "端口 ${shadowsocksport} 已成功开通！"
				fi
			else
				echo "WARNING: WARNING: 防火墙已关闭或未安装, 请手动安装！""
			fi		
        fi
    fi
    echo "防火墙设置完成..."
}

# Config ShadowsocksR
 echo "正在设置shadowsocks.json......."
function config_shadowsocks(){
    cat > /etc/shadowsocks.json<<-EOF
{
        "server": "0.0.0.0",
	"server_ipv6": "::",
	"server_port": ${shadowsocksport},
	"local_address": "127.0.0.1",
	"local_port": 1081,
	"password": "${shadowsockspwd}",
	"timeout": 600,
	"udp_timeout": 120,
	"method": "chacha20",
	"protocol": "auth_sha1_v4_compatible",
	"protocol_param": "",
	"obfs": "http_simple_compatible",
	"obfs_param": "",
	"dns_ipv6": false,
	"connect_verbose_info": 1,
	"redirect": "",
	"fast_open": false,
	"workers": 1

}
EOF
}

  echo "shadowsocks.json 设置完成....."
  
# Install ShadowsocksR
echo "正在安装 libsodium....."
function install_ss(){
    # Install libsodium
    tar zxf libsodium-1.0.12.tar.gz
    cd $cur_dir/libsodium-1.0.12
    ./configure && make && make install
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
    ldconfig
    # Install ShadowsocksR
    cd $cur_dir
    # unzip -q manyuser.zip
    echo "正在获取源代码....."
    # mv shadowsocks-manyuser/shadowsocks /usr/local/
	git clone https://github.com/shadowsocksr/shadowsocksr.git /usr/local/shadowsocks
    if [ -f /usr/local/shadowsocks/server.py ]; then
        chmod +x /etc/init.d/shadowsocks
        echo "源代码获取成功....."
	# Add run on system start up
        if [ "$OS" == 'CentOS' ]; then
            chkconfig --add shadowsocks
            chkconfig shadowsocks on
        else
            update-rc.d -f shadowsocks defaults
        fi
        # Run ShadowsocksR in the background
	echo "ShadowsocksR后台启动....."
        /etc/init.d/shadowsocks start
        clear
        echo
        echo "恭喜你，shadowsocksR安装完成！"
        echo -e "服务器IP: \033[41;37m ${IP} \033[0m"
        echo -e "远程连接端口: \033[41;37m ${shadowsocksport} \033[0m"
        echo -e "远程连接密码: \033[41;37m ${shadowsockspwd} \033[0m"
        echo -e "本地监听IP: \033[41;37m 127.0.0.1 \033[0m"
        echo -e "本地监听端口: \033[41;37m 1080 \033[0m"
        echo -e "认证方式: \033[41;37m auth_sha1 \033[0m"
        echo -e "协议: \033[41;37m http_simple \033[0m"
        echo -e "加密方式: \033[41;37m chacha20 \033[0m"
        echo
        echo 
        echo "如果你想改变认证方式和协议，请参考网址"
        echo "https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup"
        echo
        echo "安装完毕！去享受这种愉悦感把！"
        echo
    else
        echo "Shadowsocks安装失败!"
        install_cleanup
        exit 1
    fi
}

#改成北京时间
# function check_datetime(){
	# rm -rf /etc/localtime
	# ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	# ntpdate time.windows.com
# }

# Install cleanup
function install_cleanup(){
    cd $cur_dir
    rm -f shadowsocksR.sh
    rm -f manyuser.zip
    rm -rf shadowsocks-manyuser
    rm -f libsodium-1.0.12.tar.gz
    rm -rf libsodium-1.0.12
}


# Uninstall ShadowsocksR
function uninstall_shadowsocks(){
    printf "Are you sure uninstall ShadowsocksR? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        /etc/init.d/shadowsocks status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        checkos
        if [ "$OS" == 'CentOS' ]; then
            chkconfig --del shadowsocks
        else
            update-rc.d -f shadowsocks remove
        fi
        rm -f /etc/shadowsocks.json
        rm -f /etc/init.d/shadowsocks
        rm -rf /usr/local/shadowsocks
        echo "ShadowsocksR 已成功卸载！"
    else
        echo "卸载失败！"
    fi
}


# Install ShadowsocksR
function install_shadowsocks(){
    checkos
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    install_ss
    if [ "$OS" == 'CentOS' ]; then
        firewall_set > /dev/null 2>&1
    fi
	#check_datetime
    install_cleanup
	
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks
    ;;
uninstall)
    uninstall_shadowsocks
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
