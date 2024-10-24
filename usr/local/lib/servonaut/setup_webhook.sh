#!/bin/bash

setup_webhook() {
  # Install webhook
  apt-get install -y webhook

  # Create webhook config directory and hooks file
  mkdir -p /etc/webhook
  chmod 755 /etc/webhook

  # Create webhook hooks configuration
  cat >/etc/webhook/hooks.json <<EOF
{
  "id": "servonaut-deploy",
  "execute-command": "/usr/local/lib/servonaut/auto_deploy.sh",
  "command-working-directory": "/var/www/app",
  "response-message": "Deploying application...",
  "trigger-rule": {
    "match": {
      "type": "payload-hmac-sha1",
      "secret": "$(cat /home/servonaut/.webhook_token)",
      "parameter": {
        "source": "header",
        "name": "X-Hub-Signature"
      }
    }
  }
}
EOF

  chmod 644 /etc/webhook/hooks.json

  # Create webhook service
  cat >/etc/systemd/system/webhook.service <<EOF
[Unit]
Description=GitHub Webhook Handler
After=network.target

[Service]
Type=simple
User=servonaut
Environment=WEBHOOK_SECRET=$(cat /home/servonaut/.webhook_token)
ExecStart=/usr/bin/webhook -hooks /etc/webhook/hooks.json -port 9000
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  # Enable and start webhook service
  systemctl daemon-reload
  systemctl enable webhook.service
  systemctl start webhook.service

  echo -e "\n✅ Webhook handler has been set up successfully."
  return 0
}
