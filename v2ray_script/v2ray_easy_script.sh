#!/usr/bin/bash

#=================================================================#
#   System Required:  CentOS 7+, Ubuntu 19+                       #
#   Description: One click Install v2ray server                   #
#   Author: Enthusiastic citizens                                 #
#   Intro:  https://www.iktb.xyz                                  #
#=================================================================#

v2ray_dir="/etc/v2ray"
v2ray_config="/etc/v2ray/config.json"
v2ray_access_log_path="/var/log/v2ray/access.log"
v2ray_error_log_path="/var/log/v2ray/error.log"


caddy_dir="/root/caddy"
caddy_file="/root/caddy/Caddyfile"

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
# 检查系统版本 和 安装包管理器
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}


get_version(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}
#而对于19.04和20.04+、貌似官方直接给你开启了BBR，不需要重复开启了。
sys_version(){
    local version="$(get_version)"
    local main_version=${version%%.*}
    echo $main_version
}

# 安装前检查
install_check(){
  #检查centos版本和ubuntu版本
  if check_sys sysRelease ubuntu;then
    if [ $(sys_version) -ge 19 ];then
      return 0
    else
      return 1
    fi
  elif check_sys sysRelease centos;then
    if [ $(sys_version) -ge 7 ];then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

#安装docker
install_docker(){
  if ! [ -x "$(command -v docker)" ];then
    echo "--> 检查到docker未安装 >>>>>>>> "
    echo "--> 正在安装docker 请稍等>>>>>>"
    if check_sys packageManager yum;then
      yum -y intall docker > /dev/null 2>&1
      echo "--> docker 安装完成"
    elif check_sys packageManager apt; then
      apt update > /dev/null 2>&1
      apt -y install docker.io > /dev/null 2>&1
      echo "--> docker 安装完成"
    fi
    systemctl start docker
    echo "下面开始安装 v2ray"
  else
    echo "--> 检查到docker已安装"
    docker_check=`netstat -anp | grep docker`
    if [ ! -n "$docker_check" ];then
      echo "--> 检查到docker 未启动 >>>> 正在启动docker"
      systemctl start docker
      echo "--> docker 已启动 >>> 开始安装v2ray"
    else
      echo "--> 下面开始安装 v2ray"
      echo "-----------------------------"
      echo
    fi
  fi
  #创建v2ray网络
  docker network create v2ray_network > /dev/null 2>&1
}

install_v2ray(){
  local v2ray_port=$1
  local v2ray_uuid=$2
  local v2ray_webPath=$3
  mkdir -p ${v2ray_dir}
  cat > ${v2ray_config}<<-EOF
{
    "log": {
    "loglevel": "warning",
    "access": "${v2ray_access_log_path}",
    "error": "${v2ray_error_log_path}"
  },
  "inbounds": [
    {
      "port": "${v2ray_port}",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${v2ray_uuid}",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${v2ray_webPath}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
  docker run -d --name v2rays --restart always -v /etc/v2ray:/etc/v2ray --net v2ray_network v2ray/official v2ray -config=/etc/v2ray/config.json > /dev/null 2>&1
  echo "--> v2ray 安装完成 "
}

install_caddy(){
  local v2ray_port=$1
  local v2ray_webPath=$2
  local caddy_domain=$3
  #安装caddy
  mkdir -p ${caddy_dir}
  cat > ${caddy_file}<<-EOF
${caddy_domain}
{
  encode gzip
  log {
        output file /var/log/caddy-access.log {
                roll_size 1gb
                roll_keep 5
                roll_keep_for 720h
        }
  }
  reverse_proxy ${v2ray_webPath} v2rays:${v2ray_port} {
    header_up -Origin
  }
}
EOF
     docker run --name caddy --restart always --net v2ray_network -p 443:443 -d  -v ${caddy_file}:/etc/caddy/Caddyfile caddy:2.0.0 > /dev/null 2>&1
     echo "---> caddy 安装完成"
}

install_start(){
#  echo "请输入v2ray端口号（1-65535）"
#  read -p "(Default port: ${v2ray_port}):" v2ray_port
#  [ -z "${v2ray_port}" ] && v2ray_port="9000"
#  echo "---------------------------"
#  echo "v2ray端口号：${v2ray_port}"
#  echo "---------------------------"

  echo "请输入ws_path 地址"
  read -p "(默认ws_path地址为 /rays) : " v2ray_webPath
  [ -z "${v2ray_webPath}" ] && v2ray_webPath="/rays"
  echo
  echo "-----------------------------"
  echo "ws_path地址为 :${v2ray_webPath}"
  echo "-----------------------------"
  echo
  v2ray_port=$(shuf -i 9000-19999 -n 1)
  v2ray_uuid=$(uuidgen)
  echo "-----------------------------"
  echo "随机生成的uuid为: ${v2ray_uuid}"
  echo "-----------------------------"
  echo
  read -p "(输入自己购买的域名 不要乱填 ): " caddy_domain
  echo
  echo "-----------------------------"
  echo "当前输入的域名为: ${caddy_domain}"
  echo "-----------------------------"
  echo
  echo "########################################################"
  echo -e "#  you address  : \033[41;37m ${caddy_domain} \033[0m "
  echo -e "#  you port     : \033[41;37m 443 \033[0m "
  echo -e "#  you uuid     : \033[41;37m ${v2ray_uuid} \033[0m "
  echo -e "#  you alterId  : \033[41;37m 64 \033[0m "
  echo -e "#  you protocol : \033[41;37m ws \033[0m "
  echo -e "#  you path     : \033[41;37m ${v2ray_webPath} \033[0m "
  echo "########################################################"

  install_v2ray $v2ray_port $v2ray_uuid $v2ray_webPath
  install_caddy $v2ray_port $v2ray_webPath $caddy_domain
  echo
  echo "-----------------------------"
  echo "---> v2ray 已经全部安装完成 敬请享用吧"
 }

if [ ! -n "$1" ];then
 echo "参数不能为空 请输入install 或 uninstall"
elif [ $1 == "install" ];then
  if install_check ;then
    echo
    echo "--> 开始安装"
    install_docker
    install_start
  else
    echo -e "[${red}error${plain}] 安装检查不通过 支持的系统版本为centos7+ ,ubuntu19+ 请检查系统版本后重试"
  fi
elif [ $1 == "uninstall" ];then
  printf "确定卸载v2ray脚本吗 (y/n)"
  printf "\n"
  read -p "(Default: n )" answer
  [ -z ${answer} ] && answer="n"
  if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ];then
    echo "正在卸载请稍等..."
    docker stop caddy && docker rm caddy
    docker stop v2rays && docker rm v2ray
    rm -rf /etc/v2ray
    rm -rf /root/caddy
    echo "--> v2ray卸载完成"
  else
    echo "--> 已取消卸载"
  fi
else
  echo "参数输入不正确 请输入 install 或 uninstall"
fi