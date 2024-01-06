# dast_terraform

**# zap 설치**
1.  wget -q https://github.com/zaproxy/zaproxy/releases/download/v2.14.0/ZAP_2.14.0_Linux.tar.gz
2. tar -zxvf ZAP_2.14.0_Linux.tar.gz
3. rm ZAP_2.14.0_Linux.tar.gz
4. chmod +x ./ZAP_2.14.0/zap.sh

**# zap-cli 설치**
1. pip3 install --upgrade git+https://github.com/Grunny/zap-cli.git
2. whereis zap-cli
3. mv (zap-cli설치 위치) ./ZAP_2.14.0/
