#!/bin/bash

# --- 1. 配置变量（你的专属） ---
WORKDIR="/var/www/surge"  # 或 /var/www/github_config/surge-rules
FILE_NAME="MY_Return_China.conf"
GITHUB_USER="kkchan2311"
GITHUB_REPO="surge-rules"
DOMAIN="ipv6.kkchan.uk"  # 你的域名，用于 Caddy

mkdir -p "$WORKDIR/logs"
cd "$WORKDIR" || { echo "工作目录创建失败"; exit 1; }

# --- 2. Git 初始化/检查（兼容 main/master） ---
if [ ! -d ".git" ]; then
    git init
    git remote add origin git@github.com:"$GITHUB_USER"/"$GITHUB_REPO".git
    git branch -M main  # 统一 main 分支
fi
git remote -v | grep -q "$GITHUB_REPO" || git remote set-url origin git@github.com:"$GITHUB_USER"/"$GITHUB_REPO".git

# --- 3. 生成优化 Surge 配置（马来西亚回国专用） ---
cat <<EOF > "$FILE_NAME"
[General]
compatibility-mode = 3
block-quic = true
exclude-suspended-proxies = true
tcp-fast-open = true
udp-priority = false
exclude-simple-hostnames = true
dns-server = 223.5.5.5, 114.114.114.114, 8.8.8.8, 1.1.1.1
encrypted-dns-server = https://dns.alidns.com/dns-query, https://dns.google/dns-query
hijack-dns = 8.8.8.8:53, 114.114.114.114:53
all-hybrid = true
internet-test-url = http://www.google.com/generate_204
proxy-test-url = http://www.baidu.com/generate_204
test-timeout = 3
proxy-test-udp = www.apple.com:64.6.64.6
ipv6 = false
ipv6-vif = disabled
skip-proxy = 127.0.0.1, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 100.64.0.0/10, localhost, *.local, *.crashlytics.com, *.edu.my, *.gov.my
geoip-maxmind-url = https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/Country.mmdb

[Proxy]
# WireGuard 节点（你的本地代理，测试用 baidu.com）
MY_Local_Proxy = wireguard, section-name=F16491DD, test-url=http://www.baidu.com/generate_204, ecn=true
# 添加 Hysteria2 示例（替换为你的节点）
# MY_Hysteria = hysteria2, your-server.com:443, password=yourpass, sni=your-sni.com

[Proxy Group]
# 回国优先本地代理
Return_China = select, MY_Local_Proxy, DIRECT, no-alert=0, hidden=0
# 马来西亚本地：WiFi/蜂窝直连或代理
Auto_Local = subnet, default=DIRECT, "BSSID:58:c6:7e:df:2d:51"=DIRECT, "TYPE:CELLULAR"=MY_Local_Proxy
# 国际流量
International = select, MY_Local_Proxy, DIRECT, no-alert=0, hidden=0
Fallback = fallback, MY_Local_Proxy, DIRECT, timeout=3, no-alert=0

[Rule]
# 优先级：广告/私有 > iCloud/Apple > ByteDance/抖音 > 中国 > 马来西亚 > 国际
DOMAIN-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/private.txt,DIRECT
DOMAIN-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/reject.txt,REJECT
RULE-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/system.txt,DIRECT
RULE-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/lan.txt,DIRECT
# ByteDance/抖音回国
OR,((DOMAIN-SUFFIX,amemv.com), (DOMAIN-SUFFIX,snssdk.com), (DOMAIN-SUFFIX,ixigua.com)),Return_China
DOMAIN-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/icloud.txt,DIRECT
DOMAIN-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/apple.txt,DIRECT
DOMAIN-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/google.txt,International
RULE-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/telegramcidr.txt,International
DOMAIN-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/direct.txt,Auto_Local
RULE-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/cncidr.txt,Auto_Local
GEOIP,CN,Auto_Local
# 马来西亚本地直连
GEOIP,MY,Auto_Local
DOMAIN-SET,https://cdn.jsdelivr.net/gh/Loyalsoldier/surge-rules@release/proxy.txt,International
FINAL,Auto_Local,dns-failed

[Host]
*.cn = server:223.5.5.5
*.alicdn.com = server:223.5.5.5
*.aliyun.com = server:223.5.5.5
*.taobao.com = server:223.5.5.5
*.tmall.com = server:223.5.5.5
*.qq.com = server:119.29.29.29
*.tencent.com = server:119.29.29.29
*.baidu.com = server:180.76.76.76
*.google.com = server:8.8.8.8
*.youtube.com = server:8.8.8.8
*.apple.com = server:system
*.icloud.com = server:system

[WireGuard F16491DD]
private-key = kGHfJBcGlxExvXst8w8USmqxDsiUoxV7qMgkjIH/FUU=
self-ip = 172.16.0.2
self-ip-v6 = 2606:4700:cf1:1000::25
dns-server = 1.1.1.1
mtu = 1280
peer = (public-key = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=, allowed-ips = "0.0.0.0/0, ::0/0", endpoint = 162.159.193.10:2408, keepalive = 25, client-id = 88/243/13)

[MITM]
skip-server-cert-verify = true
h2 = true
EOF

# --- 4. Git 推送 ---
git add . >/dev/null 2>&1
git commit -m "Update MY_Return_China.conf $(date +'%Y-%m-%d %H:%M')" || echo "无变更，跳过 commit"
git push -u origin main 2>>"$WORKDIR/logs/git.log" || git push origin main 2>>"$WORKDIR/logs/git.log"

RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main/$FILE_NAME"

# --- 5. 输出结果 ---
echo "✅ 配置文件生成：$WORKDIR/$FILE_NAME"
echo "📱 Surge 订阅 URL：$RAW_URL"
echo "🔗 Caddy 配置（/etc/caddy/Caddyfile）："
echo "  $DOMAIN {"
echo "      root * $WORKDIR"
echo "      file_server browse"
echo "      log { output file $WORKDIR/logs/caddy.log }"
echo "  }"
echo "💡 重启 Caddy：systemctl restart caddy"
echo "📊 测试：curl -I $RAW_URL"
echo "🔄 日志：tail -f $WORKDIR/logs/git.log"
