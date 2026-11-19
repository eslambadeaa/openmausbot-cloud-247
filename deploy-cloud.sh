#!/usr/bin/env bash
# ==============================================================================
# OpenMausBot 24/7 Automated Cloud Deployment Script
# 100% Free Hosting + High Intelligence Setup (Zero Server Management)
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}   🚀 OpenMausBot 24/7 Auto-Installer & Cloud Setup    ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Please run as root (use: sudo bash deploy-cloud.sh)${NC}"
  exit 1
fi

echo -e "\n${YELLOW}[1/5] Updating packages and checking dependencies...${NC}"
apt-get update -qq

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}[*] Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable --now docker
else
    echo -e "${GREEN}[✓] Docker is already installed.${NC}"
fi

# Install Docker Compose plugin if missing
if ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}[*] Installing Docker Compose plugin...${NC}"
    apt-get install -y -qq docker-compose-plugin
fi

INSTALL_DIR="/opt/openmausbot-247"
echo -e "\n${YELLOW}[2/5] Setting up installation directory at ${INSTALL_DIR}...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download configuration files
echo -e "${YELLOW}[*] Pulling Docker configurations...${NC}"
cat << 'EOF' > docker-compose.yml
version: "3.8"

services:
  omb:
    image: ghcr.io/milind-soni/openmausbot:latest
    container_name: openmausbot_core
    restart: always
    init: true
    shm_size: 512m
    volumes:
      - openmausbot_data:/data
      - openmausbot_edge:/run/openmausbot
    environment:
      - OMB_PORT=8799
      - OMB_WEBHOOK_PORT=8800
      - OMB_TUNNEL_SOCKET=/run/openmausbot/http.sock
      - OMB_WEBHOOK_SOCKET=/run/openmausbot/hooks.sock
      - OMB_SERVER_NAME=MausBot-Cloud-247
      - OMB_PUBLIC_URL=${OMB_PUBLIC_URL:-http://localhost:8080}
      - OMB_WEBHOOK_PUBLIC_URL=${OMB_WEBHOOK_PUBLIC_URL:-${OMB_PUBLIC_URL:-http://localhost:8080}}
      - OMB_PHONE_RELAY=1
      - OMB_OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
      - GROQ_API_KEY=${GROQ_API_KEY:-}
      - OPENAI_COMPAT_API_KEY=${OPENAI_COMPAT_API_KEY:-}
      - OPENAI_COMPAT_BASE_URL=${OPENAI_COMPAT_BASE_URL:-}
    healthcheck:
      test:
        - CMD
        - node
        - -e
        - "fetch('http://127.0.0.1:8799/api/health', { signal: AbortSignal.timeout(4000) }).then(async r => { if (!r.ok || !(await r.text()).includes('openmausbot')) process.exit(1); }).catch(() => process.exit(1))"
      interval: 15s
      timeout: 5s
      start_period: 30s
      retries: 5

  caddy:
    image: caddy:2-alpine
    container_name: openmausbot_proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "8080:80"
    environment:
      - OMB_HTTPS_HOST=${OMB_HTTPS_HOST:-}
      - OMB_BIND_ADDRESS=0.0.0.0
      - OMB_TRUSTED_PROXY_CIDRS=0.0.0.0/0 ::/0
    depends_on:
      omb:
        condition: service_started
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - openmausbot_edge:/run/openmausbot
      - caddy_data:/data
      - caddy_config:/config

volumes:
  openmausbot_data:
    name: openmausbot_persisted_data
  openmausbot_edge:
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: mode=1777,size=1m
  caddy_data:
  caddy_config:
EOF

cat << 'EOF' > Caddyfile
:80 {
	encode zstd gzip
	handle /hooks/* {
		reverse_proxy unix//run/openmausbot/hooks.sock
	}
	@trusted_https {
		host {$OMB_HTTPS_HOST:https-disabled.invalid}
		remote_ip {$OMB_TRUSTED_PROXY_CIDRS}
	}
	handle @trusted_https {
		reverse_proxy unix//run/openmausbot/http.sock {
			header_up X-Forwarded-Proto https
			header_up -Accept-Encoding
			flush_interval -1
		}
	}
	handle {
		reverse_proxy unix//run/openmausbot/http.sock {
			header_up X-Forwarded-Proto http
			header_up -Accept-Encoding
			flush_interval -1
		}
	}
}
EOF

# Setup .env if not exists
if [ ! -f .env ]; then
    echo -e "\n${YELLOW}[3/5] Configuring API Keys (Intelligence Engine)...${NC}"
    echo "Enter your OpenRouter API Key (press Enter to skip):"
    read -r user_openrouter
    echo "Enter your Groq Cloud API Key (press Enter to skip):"
    read -r user_groq

    cat << EOF > .env
COMPOSE_PROJECT_NAME=openmausbot
OMB_SERVER_NAME=MausBot-Cloud-247
OMB_HTTP_PORT=8080
OPENROUTER_API_KEY=${user_openrouter}
GROQ_API_KEY=${user_groq}
OMB_PHONE_RELAY=1
EOF
fi

echo -e "\n${YELLOW}[4/5] Starting OpenMausBot Containers...${NC}"
docker compose pull
docker compose up -d

echo -e "\n${YELLOW}[5/5] Generating Device Pairing Key & Access Info...${NC}"
sleep 5

# Obtain Public IP
SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || echo "YOUR_SERVER_IP")

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}   🎉 OpenMausBot is now RUNNING 24/7 in the Cloud!   ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Web Access: http://${SERVER_IP}:8080"
echo -e "To generate an instant Admin pairing link for Phone & Desktop app, run:"
echo -e "${BLUE}docker compose exec omb openmausbot pair --label \"Admin Mobile\"${NC}"
echo -e "======================================================\n"
