#!/usr/bin/env bash

brews=(
  android-platform-tools
  autoenv
  aws-shell
  bash
  clib
  dfc
  git
  git-extras
  iftop
  imagemagick
  lighttpd
  lnav
  mackup
  macvim
  mtr
  ncdu
  nmap
  node
  postgresql
  pgcli
  scala
  sbt
  stormssh
  thefuck
  tmux
  tree
  trash
  wget
)

casks=(
  adobe-reader
  atom
  betterzipql
  cakebrew
  cleanmymac
  commander-one
  docker-toolbox
  dropbox
  firefox
  google-chrome
  github-desktop
  hosts
  handbrake
  istat-menus
  licecap
  iterm2
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  launchrocket
  microsoft-office
  private-eye
  slack
  sublime-text
  teleport
  transmission
  transmission-remote-gui
  tunnelbear
  vlc
  volumemixer
  xquartz
)

pips=(
  pylint
  virtualenv
  virtualenvwrapper
)

gems=(
  bundle
  github-pages
  scss_lint
)

npms=(
  gulp
)

clibs=(
  bpkg/bpkg
)

bkpgs=(
)

git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "core.pager cat"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "rerere.enabled true"
  "user.name tvanantwerp"
  "user.email tom@tomvanantwerp.com"
)

apms=(
  atom-beautify
  file-icons
  language-pug
  linter-erb
  linter-jscs
  linter-jshint
  linter-jsonlint
  linter-htmlhint
  linter-markdown
  linter-php
  linter-pug
  linter-pylint
  linter-scss-lint
  linter-twig
  minimap
  nuclide
  pigments
)

fonts=(
  font-source-code-pro
)


######################################## End of app list ########################################
set +e
set -x

if test ! $(which brew); then
  echo "Installing Xcode ..."
  xcode-select --install

  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
  brew upgrade
fi
brew doctor
brew tap homebrew/dupes
brew tap homebrew/versions
brew tap homebrew/homebrew-php

fails=()

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
(cd ~/.oh-my-zsh/themes/; curl https://raw.githubusercontent.com/carloscuesta/materialshell/master/osx/iterm/materialshell-ocean.itermcolors)
sed -i '.bak' 's/^ZSH_THEME=.*/ZSH_THEME="materialshelloceanic"/g' ~/.zshrc

echo "Installing python..."
brew install pyenv
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
source ${HOME}/.pyenv
pyenv install 3.5.2
pyenv install 2.7.12
pyenv global 3.5.2

echo "Installing ruby ..."
brew install ruby-install chruby
ruby-install ruby
echo 'source /usr/local/share/chruby/chruby.sh' >> ~/.bash_profile
echo 'source /usr/local/share/chruby/chruby.sh' >> ~/.zshrc
chruby ruby-2.3.0
ruby -v

echo "Installing PHP..."
# TODO make this work
curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew
chmod +x phpbrew
sudo mv phpbrew /usr/bin/phpbrew
echo "[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc" >> ~/.bashrc
echo "[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc" >> ~/.bash_profile
echo "[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc" >> ~/.zshrc
source ~/.phpbrew/bashrc
phpbrew --debug install --stdout 7.1 as 7.1-dev +default +intl
phpbrew switch 7.1-dev
phpbrew --debug ext install xdebug 2.4.0
phpbrew --debug ext install github:krakjoe/apcu
phpbrew --debug ext install github:php-memcached-dev/php-memcached php7 -- --disable-memcached-sasl
phpbrew --debug ext install github:phpredis/phpredis php7
phpbrew install 5.6 as 5.6-dev like 7.0-dev

echo "Installing Java ..."
brew cask install java

echo "Installing packages ..."
brew info ${brews[@]}
install 'brew install' ${brews[@]}

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

echo "Installing software ..."
brew cask info ${casks[@]}
install 'brew cask install --appdir=/Applications' ${casks[@]}

echo "Installing fonts..."
install 'brew cask install' ${fonts[@]}

echo "Installing python packages..."
install 'pip install --upgrade' ${pips[@]}

echo "Installing ruby gems..."
install 'gem install' ${gems[@]}

echo "Installing secondary packages..."
install 'clib install' ${clibs[@]}
install 'bpkg install' ${bpkgs[@]}

echo "Installing node packages..."
install 'npm install --global' ${npms[@]}

echo "Installing Atom packages..."
install 'apm install' ${apms[@]}

echo "Upgrading bash ..."
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
cd; curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}
source ~/.bash_profile

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

echo "Upgrading ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system

echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo "Run `mackup restore` after DropBox has done syncing"

read -p "Hit enter to run [OSX for Hackers] script..." c
sh -c "$(curl -sL https://gist.githubusercontent.com/brandonb927/3195465/raw/osx-for-hackers.sh)"

#echo "Setting up fish shell ..."
#brew install fish chruby-fish
#echo $(which fish) | sudo tee -a /etc/shells
#mkdir -p ~/.config/fish/
#echo "source /usr/local/share/chruby/chruby.fish" >> ~/.config/fish/config.fish
#echo "source /usr/local/share/chruby/auto.fish" >> ~/.config/fish/config.fish
#echo "export GOPATH=/usr/libs/go" >> ~/.config/fish/config.fish
#echo "export PATH=$PATH:$GOPATH/bin" >> ~/.config/fish/config.fish
#chsh -s $(which fish)
#curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install | fish
#for omf in ${omfs[@]}
#do
#  fish -c "omf install ${omf}"
#done

echo "Done!"
