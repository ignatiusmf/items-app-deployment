#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

### 0. CONSTANTS ##############################################################
APP_DIR=/srv/items                           # where app.py & DB live
VENV_DIR=/opt/items_env                      # virtualenv location
GUNICORN_PORT=${GUNICORN_PORT:-3000}         # overridable gunicorn port
GUNICORN_BIND="0.0.0.0:${GUNICORN_PORT}"
DB_PATH=${DB_PATH:-$APP_DIR/items_db.sqlite} # same env var app.py respects
SERVICE_NAME=items-app                       # <- single source of truth
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_SITE=/etc/nginx/sites-available/items

echo "==> Starting setup (service=${SERVICE_NAME}, port=${GUNICORN_PORT})"

### 1. OS PACKAGE INSTALLATION ###############################################
need_pkg() { dpkg -s "$1" &>/dev/null; }

if ! need_pkg nginx || ! need_pkg python3-venv || ! need_pkg python3-pip; then
  echo "==> Installing prerequisites"
  sudo apt-get update -y
  sudo apt-get install -y nginx python3-venv python3-pip
else
  echo "==> Prerequisites already installed – skipping"
fi

### 2. PYTHON VIRTUAL ENVIRONMENT ############################################
if [ ! -d "$VENV_DIR" ]; then
  echo "==> Creating virtualenv ${VENV_DIR}"
  sudo python3 -m venv "$VENV_DIR"
  sudo "$VENV_DIR/bin/pip" install --upgrade pip
  sudo "$VENV_DIR/bin/pip" install flask gunicorn
else
  echo "==> Virtualenv exists – skipping creation"
fi

### 3. DEPLOY APPLICATION CODE ###############################################
echo "==> Deploying application code to ${APP_DIR}"
sudo mkdir -p "$APP_DIR"
sudo cp app.py "$APP_DIR/"
sudo chown -R ubuntu:ubuntu "$APP_DIR"

### 4. SYSTEMD SERVICE FOR GUNICORN ###########################################
if [ ! -f "$SERVICE_FILE" ]; then
  echo "==> Creating systemd unit ${SERVICE_NAME}.service"
  cat <<EOF | sudo tee "$SERVICE_FILE" >/dev/null
[Unit]
Description=Items API (Gunicorn / Flask)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment=DB_PATH=$DB_PATH
ExecStart=$VENV_DIR/bin/gunicorn -w 2 -b $GUNICORN_BIND app:app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now "$SERVICE_NAME"
else
  echo "==> systemd unit exists – ensuring it is running"
  sudo systemctl start "$SERVICE_NAME"
fi

### 5. NGINX REVERSE PROXY ####################################################
if [ ! -f "$NGINX_SITE" ]; then
  echo "==> Creating Nginx site config"
  cat <<EOF | sudo tee "$NGINX_SITE" >/dev/null
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:${GUNICORN_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
  sudo ln -s "$NGINX_SITE" /etc/nginx/sites-enabled/items
  sudo nginx -t
  sudo systemctl reload nginx
else
  echo "==> Nginx site already present – validating & reloading"
  sudo nginx -t
  sudo systemctl reload nginx
fi

### 6. OPTIONAL HOST FIREWALL (UFW) ###########################################
if command -v ufw &>/dev/null && sudo ufw status | grep -q active; then
  echo "==> UFW active – ensuring port 80 is permitted"
  sudo ufw allow 80/tcp
else
  echo "==> UFW inactive (or absent) – relying on AWS Security Group"
fi

### 7. SMOKE TEST #############################################################
echo "==> Performing health-check via localhost"
if curl --silent --fail http://localhost/items &>/dev/null; then
  echo "✔ API responded"
else
  echo "⚠ API failed – check 'systemctl status ${SERVICE_NAME}'"
fi

echo "✔ Setup complete – browse to http://<instance-ip>/"
