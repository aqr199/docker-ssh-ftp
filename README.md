# 在 docker 環境架設 ssh-ftp 伺服器

使用 alpine:3.21 建立 SSH FTP 伺服器

# 帳號及密碼

設定帳號及密碼, 同時設定UID, GID

```
services:
  rsync:
    ...
    environment:
      # 權限設定 (對齊宿主機 UID/GID)
      - PUID=1000
      - PGID=1000
      # SSH 帳密與密鑰
      - SSH_USER=admin
      - SSH_PASSWORD=12345678
      ...
```

# 可以限制登入的IP

多組 IP 用逗號分開

```
services:
  rsync:
    ...
    environment:
    ...
      - ALLOW_IP=192.168.50.0/24,192.168.8.0/24
    ...
```

# 安全性問題

為了安全性, 限定使用者只能在限定目錄內活動

目錄 /worker 本身不能上傳檔案
需要在 /worker 內, 掛載目錄

登入後, 直接在根目錄 /, 實際目錄是在 /worker
可以上傳檔案到 /data 目錄內

```
services:
  rsync:
    ...
    volumes:
      - ./data:/worker/data
    ...
```


# SSH 服務需要保留金鑰

存放目錄在 /ssh_keys

需要建立 volumes 來存放

```
services:
  rsync:
    ...
    volumes:
      - ssh_host_keys:/ssh_keys
    ...
volumes:
  ssh_host_keys:
```