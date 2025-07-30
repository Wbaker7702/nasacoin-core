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
git clone https://github.com/wbaker7702/nasacoin-core.git
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
rpcuser=nasauser
rpcpassword=supersecurepassword
rpcport=8332
port=8333
daemon=1
server=1
txindex=1
listen=1
EOF

# Start daemon
echo "🚀 Starting NASA Coin daemon..."
./src/nasacoind -daemon

sleep 5
echo "📡 Blockchain info:"
./src/nasacoin-cli getblockchaininfo

echo "✅ NASA Coin is running!"
