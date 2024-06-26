# syntax=docker/dockerfile:1
FROM ubuntu:latest

RUN apt update && apt install -y \
  bat \
  build-essential \
  curl \
  exa \
  fd-find \
  git \
  ripgrep \
  sudo \
  tmux \
  tree \
  unzip \
  vim \
  wget \
  zsh

WORKDIR /tmp

# Install Neovim via dpkg
RUN wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb \
  && dpkg -i nvim-linux64.deb \
  && rm nvim-linux64.deb

# Install git-delta via dpkg
ENV GIT_DELTA_VERSION="0.14.0"
ENV GIT_DELTA_DEB="git-delta-musl_${GIT_DELTA_VERSION}_amd64.deb"
RUN wget https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/${GIT_DELTA_DEB} \
  && dpkg -i ${GIT_DELTA_DEB} \
  && rm ${GIT_DELTA_DEB}

# Create a user with sudo privileges
ARG USER=andy
RUN useradd -rm -d /home/${USER} -s $(which zsh) -g root -G sudo ${USER}
RUN chown -R ${USER} /home/${USER}
RUN echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}

# Copy over dotfiles and switch to the non-root user
COPY . /home/${USER}/.dotfiles
RUN chown -R ${USER} /home/${USER}
USER ${USER}

# Install the dotfiles
WORKDIR /home/${USER}/.dotfiles
RUN ./setup.sh -t build

# Install gitstatusd
RUN /home/${USER}/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install

# Install Neovim plugins
#
# 1) The first headless run bootstraps Packer.
# 2) The second headless run installs the Packer plugins.
# 3) Then, we install the Treesitter parsers.
# 4) The fourth run installs the Lua LSP, since that may not have finished.
RUN nvim --headless +qa \
  && nvim --headless -c "autocmd User PackerComplete quitall" -c "PackerSync" \
  && nvim --headless -c "TSInstallSync all" +qa \
  && nvim --headless -c "MasonInstall lua-language-server" +qa

# Install vim plugins
RUN vim +PlugInstall +qa

WORKDIR /home/${USER}
ENTRYPOINT zsh
