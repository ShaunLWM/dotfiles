#!/bin/bash

set -e

echo "🚀 Starting React Native development environment setup..."

echo "📦 Setting up Zsh..."
chsh -s $(which zsh)

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "📦 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "📦 Installing nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "📦 Installing Node.js (LTS)..."
nvm install --lts
nvm use --lts
nvm alias default node

echo "📦 Setting up Ruby environment..."
# rbenv already installed with brew
eval "$(rbenv init -)"

# # Install Ruby (required for CocoaPods)
# RUBY_VERSION="3.2.2"
# if ! rbenv versions | grep -q "$RUBY_VERSION"; then
#     echo "📦 Installing Ruby $RUBY_VERSION..."
#     rbenv install $RUBY_VERSION
#     rbenv global $RUBY_VERSION
# fi

# Install CocoaPods
echo "📦 Installing CocoaPods..."
gem install cocoapods

# Install Xcode Command Line Tools
echo "📦 Setting up Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    xcode-select --install
    echo "⏳ Please complete the Xcode Command Line Tools installation in the popup window, then press Enter to continue..."
    read -r
fi

sudo xcodebuild -license accept 2>/dev/null || true

echo "📦 Installing iOS development tools..."
brew install ios-deploy

# Setup Android environment variables
echo "📦 Configuring Android environment..."
ANDROID_HOME="$HOME/Library/Android/sdk"

echo "📦 Configuring .zshrc..."
ZSHRC="$HOME/.zshrc"

if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Add configurations to .zshrc
cat >> "$ZSHRC" << 'EOL'

# ===== React Native Development Configuration =====

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Android SDK Configuration
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# Ruby Configuration (rbenv)
eval "$(rbenv init - zsh)"

# Python Configuration (pyenv)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ===== End React Native Configuration =====
EOL

# Configure Git signing for GitHub
echo "🔐 Setting up Git commit signing..."

# Install GPG if not already installed
if ! command -v gpg &> /dev/null; then
    echo "📦 Installing GPG..."
    brew install gnupg
fi

# Install pinentry-mac for GPG passphrase entry
if ! command -v pinentry-mac &> /dev/null; then
    echo "📦 Installing pinentry-mac..."
    brew install pinentry-mac
fi

# Configure GPG agent
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Configure gpg-agent to use pinentry-mac
cat > ~/.gnupg/gpg-agent.conf << 'EOF'
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program /opt/homebrew/bin/pinentry-mac
enable-ssh-support
EOF

# Configure GPG
cat > ~/.gnupg/gpg.conf << 'EOF'
use-agent
no-tty
EOF

# Restart gpg-agent
gpgconf --kill gpg-agent

# Check if GPG key exists
if ! gpg --list-secret-keys --keyid-format=long | grep -q "sec"; then
    echo ""
    echo "📝 No GPG key found. Let's create one for Git signing..."
    echo ""
    echo "Please enter your GitHub details:"
    read -p "Full Name: " GPG_NAME
    read -p "GitHub Email: " GPG_EMAIL
    
    # Generate GPG key
    cat > /tmp/gpg-gen-key.conf << EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $GPG_NAME
Name-Email: $GPG_EMAIL
Expire-Date: 2y
%commit
%echo done
EOF
    
    gpg --batch --generate-key /tmp/gpg-gen-key.conf
    rm /tmp/gpg-gen-key.conf
    
    # Get the GPG key ID
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "sec" | head -n 1 | awk '{print $2}' | cut -d'/' -f2)
    
    echo ""
    echo "✅ GPG key created: $GPG_KEY_ID"
    echo ""
    echo "📋 Add this public key to GitHub (Settings > SSH and GPG keys > New GPG key):"
    echo ""
    gpg --armor --export $GPG_KEY_ID
    echo ""
    echo "Press Enter after you've added the key to GitHub..."
    read -r
else
    # Use existing GPG key
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "sec" | head -n 1 | awk '{print $2}' | cut -d'/' -f2)
    echo "✅ Found existing GPG key: $GPG_KEY_ID"
fi

# Configure Git to use GPG signing
echo "📝 Configuring Git for commit signing..."
git config --global user.signingkey $GPG_KEY_ID
git config --global commit.gpgsign true
git config --global gpg.program $(which gpg)

# Add GPG to shell configuration
cat >> "$ZSHRC" << 'EOL'

# GPG Configuration
export GPG_TTY=$(tty)
EOL
