#!/bin/bash
# 配置（你的 repo）
REPO_PATH="/var/www/github_config/surge-rules"
GITHUB_USER="kkchan2311"
GITHUB_REPO="surge-rules"
FILE_NAME="malaysia-back-cn.conf"

cd $REPO_PATH || { echo "目录不存在"; exit 1; }

# 初始化 Git
if [ ! -d ".git" ]; then
    git init
    git remote add origin git@github.com:$GITHUB_USER/$GITHUB_REPO.git
fi

# 生成完整 conf
cat <<'EOF' > $FILE_NAME
[General]
dns-server = 119.29.29.29, 223.5.5.5, 8.8.8.8
enhanced-mode = true
bypass-system = true
internet-test-url = http://www.baidu.com

[Proxy Group]
Return_China = url-test, HK-RELAY, SG-CN, url=http://www.baidu.com, interval=300  # 替换你的节点
Auto_Local = subnet, default=DIRECT, "BSSID:58:c6:7e:df:2d:51"=DIRECT, "TYPE:CELLULAR"=PROXY
PROXY = select, DIRECT, Return_China

[Rule]
RULE-SET,https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/reject.txt,REJECT
RULE-SET,https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/bytedance.txt,Return_China
RULE-SET,https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/apple.txt,DIRECT
RULE-SET,https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/china.txt,Return_China
RULE-SET,https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/cnmedia.txt,Return_China
GEOIP,CN,Return_China
GEOIP,MY,DIRECT
FINAL,PROXY,dns-failed
EOF

# Git 推送
git add .
git commit -m "Auto-update Surge rules $(date +'%Y-%m-%d %H:%M')"
git push origin main

echo "更新完成！托管 URL: https://raw.githubusercontent.com/kkchan2311/surge-rules/main/$FILE_NAME"
