NET_BRIDGE="vmbr1"
if ! grep -q "$NET_BRIDGE" /etc/network/interfaces; then
  echo "🛠️ Creating new Linux bridge $NET_BRIDGE..."
  echo -e "\nauto $NET_BRIDGE\niface $NET_BRIDGE inet manual\n    bridge_ports none\n    bridge_stp off\n    bridge_fd 0" >> /etc/network/interfaces
  ifup $NET_BRIDGE
else
  echo "✅ Bridge $NET_BRIDGE already exists."
fi

echo "📦 Installing ntopng, arp-scan, and netdiscover in the Dashy container..."
apt update
apt install -y gnupg ca-certificates wget lsb-release software-properties-common arp-scan netdiscover

wget -qO - https://packages.ntop.org/apt/ntop.key | apt-key add -
DISTRO=$(lsb_release -s -c)
echo "deb https://packages.ntop.org/apt/$DISTRO/ ntopng all" > /etc/apt/sources.list.d/ntopng.list
echo "deb https://packages.ntop.org/apt/$DISTRO/ nprobe all" >> /etc/apt/sources.list.d/ntopng.list

apt update
apt install -y ntopng

systemctl enable ntopng
systemctl start ntopng

echo "📡 Setting up scan-based diagram server..."
mkdir -p /opt/scan
cat <<'EOF' > /opt/scan/serve_diagram.sh
#!/bin/bash
arp-scan --localnet > /opt/scan/scan.txt
echo "graph TD" > /opt/scan/scan.mmd
awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print "Network --> " $1 "[\\"" $2 "<br>" $3 "\\"]"}' /opt/scan/scan.txt >> /opt/scan/scan.mmd
cat <<HTML > /opt/scan/index.html
<!DOCTYPE html>
<html>
<head>
<script type="module">
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs";
mermaid.initialize({ startOnLoad: true });
</script>
</head>
<body>
<div class="mermaid">
$(cat /opt/scan/scan.mmd)
</div>
</body>
</html>
HTML
python3 -m http.server 8080 --directory /opt/scan
EOF

chmod +x /opt/scan/serve_diagram.sh
nohup /opt/scan/serve_diagram.sh >/dev/null 2>&1 &

echo "✅ Done! You can now view:"
echo "🌐 ntopng dashboard: http://$(hostname -I | awk '{print $1}'):3000"
echo "🌐 Network diagram:  http://$(hostname -I | awk '{print $1}'):8080/index.html"

echo "🧩 Embedding diagram into Dashy..."
DASHY_CONF="/app/public/conf.yml"
echo -e '\n- name: Live Network Diagram\n  icon: mdi-network\n  items:\n    - title: Current LAN Devices\n      url: http://localhost:8080/index.html\n      target: iframe' >> $DASHY_CONF

if [[ "$1" == "uninstall" ]]; then
  echo "🧼 Uninstalling ntopng, arp-scan, netdiscover, scan server, and Dashy block..."

  echo "🛑 Stopping services..."
  systemctl stop ntopng
  systemctl disable ntopng

  echo "🗑️ Removing packages..."
  apt remove -y ntopng arp-scan netdiscover
  apt autoremove -y

  echo "🧹 Cleaning up scan files..."
  rm -rf /opt/scan
  rm -f /etc/apt/sources.list.d/ntopng.list
  apt update

  echo "✂️ Removing Dashy config block..."
  DASHY_CONF="/app/public/conf.yml"
  if [ -f "$DASHY_CONF" ]; then
    awk '/^- name: Live Network Diagram/{f=1; next} /^- name: /{f=0} !f' "$DASHY_CONF" > "${DASHY_CONF}.tmp" && mv "${DASHY_CONF}.tmp" "$DASHY_CONF"
  fi

  echo "✅ Uninstall complete."
  exit 0
fi