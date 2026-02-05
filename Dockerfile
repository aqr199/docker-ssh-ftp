# 使用最新穩定版 Alpine
FROM alpine:3.21

# 1. 合併安裝與目錄建立，減少 Layer
# - shadow: 用於 usermod/groupmod
# - openssh: SSH 服務
# - rsync: 同步工具
# - bash: 腳本執行環境
RUN apk add --no-cache \
    openssh \
    bash \
    shadow && \
    # 建立 SSH 執行所需目錄
    mkdir -p /run/sshd /worker /ssh_keys /etc/ssh/sshd_config.d && \
    # 安全性優化：清空預設的主機金鑰，強制由 entrypoint 產生
    rm -f /etc/ssh/ssh_host_*_key*

# 2. 設定元數據
LABEL maintainer="su.charlie@gmail.com" \
      description="SSH FTP - 支援 UID/GID 切換與 IP 限制" \
      version="1.0"

# 3. 複製檔案並設定權限
# 使用 --chmod 是 Docker 較新版本的語法，可以直接在複製時設權限
COPY README.md /README.md
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4. 設定預設環境變數
ENV SSH_USER=admin \
    SSH_UID=1000 \
    SSH_GID=1000 \
    ALLOW_IP=0.0.0.0/0


# SSH 預設埠
EXPOSE 22

# 使用 Entrypoint 處理邏輯，CMD 執行服務
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]

