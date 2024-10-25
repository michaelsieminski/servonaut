#!/bin/bash

setup_webhook() {
  # Install webhook
  apt-get install -y webhook

  # Create webhook config directory and hooks file
  mkdir -p /etc/webhook
  chmod 755 /etc/webhook

  # Configure sudo permissions for webhook
  cat >/etc/sudoers.d/webhook <<EOF
servonaut ALL=(ALL) NOPASSWD: /bin/systemctl restart nuxt.service
EOF
  chmod 440 /etc/sudoers.d/webhook

  # Create webhook hooks configuration
  cat >/etc/webhook/hooks.json <<EOF
[
  {
    "id": "servonaut-deploy",
    "execute-command": "/usr/local/lib/servonaut/auto_deploy.sh",
    "command-working-directory": "/var/www/app",
    "trigger-rule": {
      "and": [
        {
          "match": {
            "type": "payload-hash-sha1",
            "secret": "$(cat /home/servonaut/.webhook_token)",
            "parameter": {
              "source": "header",
              "name": "X-Hub-Signature"
            }
          }
        },
        {
          "match": {
            "type": "value",
            "value": "refs/heads/main",
            "parameter": {
              "source": "payload",
              "name": "ref"
            }
          }
        }
      ]
    }
  }
]
EOF

  chmod 644 /etc/webhook/hooks.json

  # Ensure webhook can access certificates
  mkdir -p /var/lib/caddy/.local/share/caddy/certificates
  chown -R servonaut:servonaut /var/lib/caddy/.local/share/caddy/certificates
  chmod -R 755 /var/lib/caddy/.local/share/caddy/certificates

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

  # Restart webhook and caddy services
  systemctl restart caddy.service
  systemctl restart webhook.service

  echo -e "\n✅ Webhook handler has been set up successfully."
  return 0
}
