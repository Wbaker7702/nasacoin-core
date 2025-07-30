#!/bin/bash

set -e

echo "🚀 Starting NASA Coin Build and Setup..."

# Install dependencies
echo "🔧 Installing build dependencies..."
sudo apt update
sudo apt install -y \
  build-essential libtool autotools-dev automake pkg-config \
  libssl-dev libevent-dev bsdmainutils libboost-all-dev \
  libdb-dev libdb++-dev git

# Clone repo
echo "📦 Cloning NASA Coin source..."
git clone https://github.com/YOUR-USERNAME/nasacoin-core.git
cd nasacoin-core

# Build NASA Coin
echo "⚙️ Building NASA Coin..."
./autogen.sh
./configure
make -j$(nproc)

# Setup configuration
echo "🛠 Creating nasacoin.conf..."
mkdir -p ~/.nasacoin
cat <<EOF > ~/.nasacoin/nasacoin.conf
rpcuser=$user
rpcpassword=supersecurepassword
rpcport=8332
port=8333
daemon=1
server=1
txindex=1
listen=1
EOF

# Move binaries to /usr/local/bin for global access
sudo cp src/nasacoind /usr/local/bin/
sudo cp src/nasacoin-cli /usr/local/bin/
sudo cp src/nasacoin-tx /usr/local/bin/

# Create systemd service
echo "📡 Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/nasacoind.service
[Unit]
Description=NASA Coin Node
After=network.target

[Service]
ExecStart=/usr/local/bin/nasacoind -daemon
ExecStop=/usr/local/bin/nasacoin-cli stop
User=$USER
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable nasacoind
sudo systemctl start nasacoind

echo "✅ NASA Coin service installed and started!"
sleep 3
nasacoin-cli getblockchaininfo

# Create a dedicated user for nasacoin (if not already created)
if ! id "nasacoin" >/dev/null 2>&1; then
  echo "👤 Creating system user 'nasacoin'..."
  sudo useradd -m -s /bin/bash nasacoin
fi

# Set up nasacoin.conf for that user
echo "📁 Setting up config for nasacoin user..."
sudo -u nasacoin mkdir -p /home/nasacoin/.nasacoin
cat <<EOF | sudo tee /home/nasacoin/.nasacoin/nasacoin.conf >/dev/null
rpcuser=nasauser
rpcpassword=supersecurepassword
rpcport=8332
port=8333
daemon=1
server=1
txindex=1
listen=1
EOF

# Fix ownership
sudo chown -R nasacoin:nasacoin /home/nasacoin/.nasacoin

# Create systemd service
echo "📡 Creating systemd service for user 'nasacoin'..."
cat <<EOF | sudo tee /etc/systemd/system/nasacoind.service
[Unit]
Description=NASA Coin Node (User: nasacoin)
After=network.target

[Service]
ExecStart=/usr/local/bin/nasacoind -daemon -conf=/home/nasacoin/.nasacoin/nasacoin.conf -datadir=/home/nasacoin/.nasacoin
ExecStop=/usr/local/bin/nasacoin-cli -conf=/home/nasacoin/.nasacoin/nasacoin.conf stop
User=nasacoin
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable nasacoind
sudo systemctl start nasacoind

echo "✅ NASA Coin node running under 'nasacoin' user"
