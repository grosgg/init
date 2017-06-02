ruby_version='2.4.1'

fancy_echo() {
  printf "\n%b\n" "$1"
}

install_if_needed() {
  local package="$1"

  if [ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    sudo aptitude install -y "$package";
  fi
}

append_to_zshrc() {
  local text="$1" zshrc
  local skip_new_line="$2"

  if [[ -w "$HOME/.zshrc.local" ]]; then
    zshrc="$HOME/.zshrc.local"
  else
    zshrc="$HOME/.zshrc"
  fi

  if ! grep -Fqs "$text" "$zshrc"; then
    if (( skip_new_line )); then
      printf "%s\n" "$text" >> "$zshrc"
    else
      printf "\n%s\n" "$text" >> "$zshrc"
    fi
  fi
}

#!/usr/bin/env bash

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT
set -e

if [[ ! -d "$HOME/.bin/" ]]; then
  mkdir "$HOME/.bin"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
fi

append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

if ! grep -qiE 'xenial' /etc/os-release; then
  fancy_echo "Sorry! we don't currently support that distro."
  exit 1
fi

fancy_echo "Updating system packages ..."
  if command -v aptitude >/dev/null; then
    fancy_echo "Using aptitude ..."
  else
    fancy_echo "Installing aptitude ..."
    sudo apt-get install -y aptitude
  fi

fancy_echo "Add official MongoDB repository"
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
  echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

  sudo aptitude update


# Tools
fancy_echo "Installing git, for source control management ..."
  install_if_needed git

fancy_echo "Installing vim ..."
  install_if_needed vim

fancy_echo "Installing tmux, to save project state and switch between projects ..."
  install_if_needed tmux

fancy_echo "Installing The Silver Searcher (better than ack or grep) to search the contents of files ..."
  install_if_needed silversearcher-ag

fancy_echo "Installing watch, to execute a program periodically and show the output ..."
  install_if_needed watch

fancy_echo "Installing curl ..."
  install_if_needed curl

fancy_echo "Installing ctags, to index files for vim tab completion of methods, classes, variables ..."
  install_if_needed exuberant-ctags

fancy_echo "Installing zsh ..."
  install_if_needed zsh

fancy_echo "Installing oh-my-zsh ..."
  if [[ ! -d "$HOME/.oh-my-zsh/" ]]; then
    sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
    append_to_zshrc 'plugins=(tmux git ruby bundler rails capistrano)'
  fi

# Ruby
fancy_echo "Installing libraries for common gem dependencies ..."
  install_if_needed build-essential
  install_if_needed patch
  install_if_needed libreadline-dev
  install_if_needed libssl-dev
  install_if_needed zlib1g-dev

fancy_echo "Installing rbenv"
  if [[ ! -d "$HOME/.rbenv/" ]]; then
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  fi
  cd ~/.rbenv && src/configure && make -C src
  append_to_zshrc 'export PATH="$HOME/.rbenv/bin:$PATH"'
  append_to_zshrc 'eval "$(rbenv init -)"'
  source ~/.zshrc
  type rbenv

fancy_echo "Installing ruby-build"
  if [[ ! -d "$HOME/.rbenv/plugins/ruby-build/" ]]; then
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  fi
  rbenv rehash

fancy_echo "Installing latest ruby version ($ruby_version)"
  if [[ ! -d "$HOME/.rbenv/versions/$ruby_version" ]]; then
    rbenv install $ruby_version
  fi
  rbenv local $ruby_version

# DB
fancy_echo "Installing Postgres"
  install_if_needed postgresql

fancy_echo "Installing MongoDB"
  install_if_needed mongodb-org

fancy_echo "Creating service for MongoDB"
  if [[ ! -f /etc/systemd/system/mongodb.service ]]; then
    sudo wget -O /etc/systemd/system/mongodb.service https://raw.githubusercontent.com/grosgg/init/master/mongodb.service
    sudo systemctl start mongodb
    sudo systemctl status mongodb
    sudo systemctl enable mongodb
  fi

# Extras
fancy_echo "Installing node, to render the rails asset pipeline ..."
  install_if_needed nodejs

fancy_echo "Changing your shell to zsh ..."
  chsh -s $(which zsh)

# Gems
fancy_echo "Updating to latest Rubygems version ..."
  gem update --system

fancy_echo "Installing Bundler to install project-specific Ruby gems ..."
  gem install bundler --no-document --pre

fancy_echo "Configuring Bundler for faster, parallel gem installation ..."
  number_of_cores=$(nproc)
  bundle config --global jobs $((number_of_cores - 1))

fancy_echo "Installing Heroku CLI client ..."
  curl -s https://toolbelt.heroku.com/install-ubuntu.sh | sh
