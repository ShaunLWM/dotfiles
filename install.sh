#!/bin/sh

echo "Installing brew..."

# https://github.com/StevenJPx2/dotfiles/blob/main/install.sh
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone https://github.com/ShaunLWM/dotfiles.git
cd dotfiles || exit

echo "Installed brew! 🎉"

# ~~~~~~

echo "Running setup..."

/bin/bash -c "scripts/setup.sh"

echo "Setup done!"

# ~~~~~~

echo "Installing brew bundle..."

cp ./Brewfile ~/Brewfile
brew bundle install

echo "Installed brew bundle!"

# ~~~~~~

echo "Running post setup..."

/bin/bash -c "scripts/post_setup.sh"

echo "Post Setup done!"
