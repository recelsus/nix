{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty
    chromium
    noto-fonts-cjk-sans
  ];

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };

    displayManager.lightdm = {
      enable = true;
    };
    
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        i3status
        dmenu
      ];
    };
  };

  i18n = {
    defaultLocale = "ja_JP.UTF-8";
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = [ pkgs.fcitx5-mozc ];
    };
  };
    

  environment.variables = {
    "GTK_IM_MODULE" = "fcitx";
    "QT_IM_MODULE" = "fcitx";
    "XMODIFIERS" = "@im=fcitx";
    "LANG" = "ja_JP.UTF-8";
  };
}

