# v2ray 一键安装脚本
- 支持centos7+ 和 Ubuntu19+ 系统
###  下载安装
 ``` shell script
wget --no-check-certificate -O v2ray_easy_script.sh https://https://raw.githubusercontent.com/ikownthat/v2ray_ws_tls/main/v2ray_script/v2ray_easy_script.sh
chmod +x v2ray_easy_script.sh
./v2ray_easy_script.sh 2>&1 | tee v2ray_easy_script.log
 ```
### 卸载
 ``` shell script
bash v2ray_easy_script.sh uninstall
```
v2ray 服务端配置文件
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

