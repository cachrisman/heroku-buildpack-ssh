#!/usr/bin/env bash

if [[ "$DYNO" != *run.* ]] && [ "$SSH_ENABLED" = "true" ]; then
  ssh_port=${SSH_PORT:-"2222"}

  if [ -n "$NGROK_API_TOKEN" ]; then
    NGROK_OPTS="${NGROK_OPTS} --authtoken ${NGROK_API_TOKEN}"
  fi

  banner_file="/app/.ssh/banner.txt"
  cat << EOF > ${banner_file}
Connected to $DYNO
EOF

  echo "Starting sshd for $(whoami)"
  /usr/sbin/sshd -f /app/.ssh/sshd_config -o "Port ${ssh_port}" -o "Banner ${banner_file}"

  # Start the tunnel
  ngrok_cmd="ngrok tcp -log stdout ${NGROK_OPTS} ${ssh_port}"
  echo "Starting ngrok tunnel"
  eval "$ngrok_cmd &"
  sleep 2
  echo -e "id_rsa:\n$(cat /app/.ssh/id_rsa)"
  uri=$(curl -s localhost:4040/api/tunnels | sed -rn 's/.*(tcp:\/\/..tcp.ngrok.io:[[:digit:]]{5}).*/\1/p')
  echo "Connection URI: $(whoami)@$uri"
fi
