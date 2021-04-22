# v2ray 一键安装脚本
  支持centos7+ 和 Ubuntu19+ 系统
 - [安装v2ray脚本](#下载安装)
 - [卸载v2ray脚本](#卸载)
 - [重启v2ray](#重启v2ray)
 - [重启caddy](#重启caddy)

###  下载安装
 ``` shell script
wget --no-check-certificate -O v2ray_easy_script.sh https://raw.githubusercontent.com/ikownthat/v2ray_ws_tls/main/v2ray_script/v2ray_easy_script.sh
chmod +x v2ray_easy_script.sh
./v2ray_easy_script.sh 2>&1 | tee v2ray_easy_script.log
 ```
### 卸载
 ``` shell script
bash v2ray_easy_script.sh uninstall
```
> v2ray 服务端配置文件

 配置文件地址 /etc/v2ray/config.json
``` json
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
```
>caddy配置文件

配置文件地址 /root/Caddyfile
``` json
${caddy_domain} #你的域名 (如果想修改域名 把这行更换成新域名 重启caddy)
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
```
#### 重启caddy
``` shell script
docker restart caddy
```
#### 重启v2ray
``` shell script
docker restart v2rays
```
>修改配置文件 需要重启对应的docker服务

