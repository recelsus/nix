{ config, pkgs, ... }:

let
  env = config.env;
in
{
  home.username = env.user ;
  home.homeDirectory = "/home/${env.user}";

  home.packages = with pkgs; [
    zip
    xz
    unzip
    p7zip

    neovim
    tmux
    ripgrep
    fzf

    jq
    which
    tree
    screenfetch
    chezmoi

    nodejs
    clang
    cmake
    gnumake
    docker-compose
  ];

  programs.git = {
    enable = true;
    userName = env.git_user;
    userEmail = env.git_email;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "24.11";
}
