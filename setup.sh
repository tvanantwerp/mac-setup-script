#!/usr/bin/env bash

brews=(
  aws-shell
  bash
  clib
  git
  git-extras
  imagemagick
  macvim
  ncdu
  node
  stormssh
  tmux
  tree
  wget
  yarn
)

casks=(
  alfred
  android-platform-tools
  cyberduck
  docker
  dropbox
  firefox
  gitkraken
  google-chrome
  iterm2
  licecap
  microsoft-office
  qlcolorcode
  qlimagesize
  qlmarkdown
  qlstephen
  qlvideo
  quicklook-csv
  quicklook-json
  quicklookase
  slack
  sublime-text
  visual-studio-code
  vlc
  webpquicklook
  xquartz
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

code_extensions=(
  "aaron-bond.better-comments"
  "CoenraadS.bracket-pair-colorizer"
  "dbaeumer.vscode-eslint"
  "dsznajder.es7-react-js-snippets"
  "Equinusocio.vsc-material-theme"
  "felixfbecker.php-intellisense"
  "formulahendry.auto-rename-tag"
  "ms-python.python"
  "ms-vscode.cpptools"
  "ms-vscode.csharp"
  "ms-vscode.powershell"
  "ms-vscode.sublime-keybindings"
  "PeterJausovec.vscode-docker"
  "PKief.material-icon-theme"
  "pnp.polacode"
  "rebornix.ruby"
  "vsmobile.vscode-react-native"
  "wix.vscode-import-cost"
  "zhuangtongfa.material-theme"
)

fonts=(
  font-anonymouspro-nerd-font
  font-droidsansmono-nerd-font
  font-firacode-nerd-font
  font-sourcecodepro-nerd-font
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
  cmd=$1 # the install command is the first arg
  shift # move to the second arg
  for pkg in $@; # all remaining args are things to install
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
(cd ~/.oh-my-zsh/custom/themes/; curl -o powerlevel9k.zip https://codeload.github.com/bhilburn/powerlevel9k/zip/master; unzip powerlevel9k.zip; mv powerlevel9k-master powerlevel9k; rm powerlevel9k.zip)
sed -i '.bak' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel9k/powerlevel9k"/g' ~/.zshrc


echo "Installing python..."
brew install pyenv
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
source ${HOME}/.pyenv
pyenv install 3.6.5
pyenv install 2.7.15
pyenv global 3.6.5

echo "Installing ruby ..."
brew install ruby
ruby -v

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

echo "Installing node packages..."
install 'yarn global add' ${npms[@]}

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

echo "Installing VS Code extensions..."
install 'code --install-extension' ${code_extensions[@]}

echo "Cleaning up ..."
brew cleanup
brew cask cleanup

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

read -p "Hit enter to run [OSX for Hackers] script..." c
sh -c "$(curl -sL https://gist.githubusercontent.com/brandonb927/3195465/raw/osx-for-hackers.sh)"

echo "Done!"
