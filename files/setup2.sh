#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# HARD-CODED PARAMS
SERVICE_NAME=items-app 
APP_DIR=/srv/${SERVICE_NAME}
VENV_DIR=${APP_DIR}/venv

# TUNABLE PARAMPS
DB_PATH=${DB_PATH:-$APP_DIR/items_db.sqlite}

echo "==> Starting setup (service=${SERVICE_NAME}, db_path=${DB_PATH})"


# STEP 1: INSTALLING OS PACKAGES
need_pkg() { dpkg -s "$1" &>/dev/null; }

if ! need_pkg nginx || ! need_pkg python3-venv || ! need_pkg python3-pip; then
  echo "==> Installing prerequisites"
  sudo apt-get update -y
  sudo apt-get install -y nginx python3-venv python3-pip
else
  echo "   - SKIP - prerequisites installed"
fi

## STEP 2: CREATING APP DIRECTORY
sudo mkdir -p "$APP_DIR"
sudo cp app.py "$APP_DIR/" # TODO: WHAT HAPPENS WHEN THE APP.PY CHANGES? VENV PACKAGES MIGHT NOT BE SUFFICIENT AND DEPLOYMENT WOULD FAIL
sudo chown -R ubuntu:ubuntu "$APP_DIR"

# STEP 3: CREATING VIRTUAL ENVIRONMENT AND INSTALLING PYTHON PACKAGES
if [ ! -d "$VENV_DIR" ]; then
  echo "==> Creating virtualenv ${VENV_DIR}"
  sudo python3 -m venv "$VENV_DIR"
  sudo "$VENV_DIR/bin/pip" install --upgrade pip
  sudo "$VENV_DIR/bin/pip" install flask gunicorn
else
  echo "   - SKIP - venv exists"
fi

SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

UNIT_CONTENT=$(cat <<EOF
[Unit]
Description=Items API (Gunicorn / Flask)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment=DB_PATH=$DB_PATH
ExecStart=$VENV_DIR/bin/gunicorn -w 2 -b 0.0.0.0:3000 app:app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
)

# Compare existing unit file to desired version (ignore whitespace)
if [ ! -f "$SERVICE_FILE" ] || ! diff -q <(echo "$UNIT_CONTENT") "$SERVICE_FILE" &>/dev/null; then
  echo "==> Writing systemd unit: $SERVICE_NAME"
  echo "$UNIT_CONTENT" | sudo tee "$SERVICE_FILE" >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable --now "$SERVICE_NAME"
  sudo systemctl restart "$SERVICE_NAME"
else
  echo "   - SKIP - systemd unit already matches desired state"
fi

NGINX_SITE=/etc/nginx/sites-available/${SERVICE_NAME}
NGINX_LINK=/etc/nginx/sites-enabled/${SERVICE_NAME}

DESIRED_NGINX_CONFIG=$(cat <<EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
)

if [ ! -f "$NGINX_SITE" ] || ! diff -q <(echo "$DESIRED_NGINX_CONFIG") "$NGINX_SITE" &>/dev/null; then
  if [ -L /etc/nginx/sites-enabled/default ]; then
    echo "==> Removing default Nginx site"
    sudo rm /etc/nginx/sites-enabled/default
  fi
  echo "==> Writing Nginx reverse proxy config)"
  echo "$DESIRED_NGINX_CONFIG" | sudo tee "$NGINX_SITE" >/dev/null

  # Only link if the symlink doesn't exist
  [ -L "$NGINX_LINK" ] || sudo ln -s "$NGINX_SITE" "$NGINX_LINK"

  sudo nginx -t
  sudo systemctl reload nginx
else
  echo "   - SKIP - nginx config already up to date"
fi


