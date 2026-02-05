rsync
限定IP, 帳號上傳

## Dockerfile

```
FROM alpine:3.23.2

RUN apk add --no-cache rsync bash

# 複製啟動腳本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 873

ENTRYPOINT ["/entrypoint.sh"]
```

## entrypoint.sh

```
#!/bin/bash
set -e

# 設定預設變數 (僅用於動態生成時)
RSYNC_UID=${RSYNC_UID:-1000}
RSYNC_GID=${RSYNC_GID:-1000}
RSYNC_USER=${RSYNC_USER:-backup_user}
RSYNC_PASSWORD=${RSYNC_PASSWORD:-pass123}

# 建立使用者與群組 (確保 UID/GID 在容器記憶體中存在)
addgroup -g "$RSYNC_GID" rsyncgroup || echo "Group exists"
adduser -u "$RSYNC_UID" -G rsyncgroup -s /bin/sh -D rsyncuser || echo "User exists"

# --- 關鍵檢查：如果 /etc/rsyncd.conf 沒被掛載，才自動生成 ---
if [ ! -f "/etc/rsyncd.conf" ]; then
    echo "No custom config found, generating default rsyncd.conf..."
    cat <<EOF > /etc/rsyncd.conf
uid = rsyncuser
gid = rsyncgroup
use chroot = no
log file = /dev/stdout
reverse lookup = no

[backup_data]
    path = /data
    comment = Default Backup Module
    read only = no
    auth users = $RSYNC_USER
    secrets file = /etc/rsyncd.secrets
    hosts allow = ${ALLOW_IPS:-0.0.0.0/0}
    hosts deny = *
EOF
fi

# 處理秘密檔 (這部分通常保持動態生成比較方便，或者您也可以比照辦理)
echo "${RSYNC_USER}:${RSYNC_PASSWORD}" > /etc/rsyncd.secrets
chown root:root /etc/rsyncd.secrets
chmod 600 /etc/rsyncd.secrets

# 確保資料目錄權限
chown "$RSYNC_UID":"$RSYNC_GID" /data

echo "Rsync server starting..."
exec rsync --daemon --no-detach --config=/etc/rsyncd.conf
```

## 建立

docker build -t aqr199/rsync:alpine .

## docker-compose.yml

services:
  rsync:
    build: .
    container_name: rsync_flexible
    networks:
      network_pd:
        ipv4_address: 192.168.50.120
    ports:
      - "873:873"
    environment:
      # 在這裡設定帳號密碼
      - RSYNC_USER=webmgr
      - RSYNC_PASSWORD=icYwJBq6rRFwz0u9Nft9
      # 設定主機對應的 UID/GID (可用 id 指令查詢)
      - RSYNC_UID=1000
      - RSYNC_GID=1000
      # 限定 IP 來源
      - ALLOW_IPS=192.168.50.0/24, 10.10.1.50
    volumes:
      - ./data:/data
      #- ./rsyncd.conf:/etc/rsyncd.conf:ro
    restart: always
networks:
  network_pd:
    external: true


## 連線測試

rsync --list-only webmgr@192.168.50.120::backup_data
rsync -avz local_file.txt my_admin@192.168.50.120::backup_data
rsync -avz ./test/. webmgr@192.168.50.120::backup_data/test/

## 自訂 rsyncd.conf

```
uid = rsyncuser
gid = rsyncgroup
use chroot = no
log file = /dev/stdout
reverse lookup = no

[backup_data]
    path = /data
    comment = Dynamic Rsync Volume
    read only = no
    auth users = webmgr
    secrets file = /etc/rsyncd.secrets
    hosts allow = 192.168.50.0/24
    hosts deny = *
```

# docker-ssh-ftp
