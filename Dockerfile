FROM ghcr.io/milind-soni/openmausbot:latest

USER root

# Install socat for transparent loopback proxy to port 7860
RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# Ensure persistent data directory has correct permissions for user (1000)
RUN mkdir -p /data && chown -R 1000:1000 /data

EXPOSE 7860
EXPOSE 8080

ENV HOME=/data
ENV OMB_PORT=8799

USER 1000

CMD ["/bin/sh", "-c", "socat TCP-LISTEN:7860,fork,reuseaddr TCP:127.0.0.1:8799 & exec node dist-server/server-launcher.js"]
