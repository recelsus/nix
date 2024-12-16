{
  description = "NixOS Configuration with Home Manager (External)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import /etc/nixos/hardware-configuration.nix) # ローカルのhardware-configuration.nixを直接参照

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users = {
                # ローカルのenv.nixから動的にユーザー名を取得
                ${(import /etc/nixos/env.nix).user or "default-user"} =
                  import ./types/${(import /etc/nixos/env.nix).type or "default"}.nix;
              };
            };
          }

          {
            # ブートローダー設定
            boot.loader.grub.enable = true;
            boot.loader.grub.devices = [ (import /etc/nixos/env.nix).bootDevice or "/dev/sda" ];

            # ネットワーク設定
            networking = {
              hostName = (import /etc/nixos/env.nix).hostname or "nixos";
              defaultGateway = (import /etc/nixos/env.nix).gateway or "192.168.1.1";
              interfaces.eth0.ipv4.addresses = [ {
                address = (import /etc/nixos/env.nix).ipv4Address or "192.168.1.100";
                prefixLength = 24;
              } ];
              nameservers = (import /etc/nixos/env.nix).nameservers or [ "8.8.8.8" ];
              firewall.enable = (import /etc/nixos/env.nix).firewall or false;
              firewall.allowedTCPPorts = (import /etc/nixos/env.nix).allowedPorts or [];
            };

            # ユーザー設定
            users.users."${(import /etc/nixos/env.nix).user or "default-user"}" = {
              isNormalUser = true;
              extraGroups = (import /etc/nixos/env.nix).groups or [];
              initialPassword = (import /etc/nixos/env.nix).password or "default-password";
              openssh.authorizedKeys.keys = (import /etc/nixos/env.nix).authorizedKeys or [];
            };

            # Sudo設定
            security.sudo.extraRules = [
              {
                groups = ["wheel"];
                commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
              }
            ];

            # SSH有効化
            services.openssh.enable = true;

            # Docker有効化
            virtualisation.docker.enable = true;

            # GUI設定
            imports = if (import /etc/nixos/env.nix).gui then [ ./gui-config.nix ] else [];
          }
        ];
      };
    };
  };
}
