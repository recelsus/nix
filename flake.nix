{
  description = "NixOS Configuration with Home Manager (External)";

  inputs = {
    # NixpkgsとHome Manager
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ローカルファイルを参照
    config-env = {
      url = "path:/etc/nixos/env.nix";
    };
    config-hardware = {
      url = "path:/etc/nixos/hardware-configuration.nix";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, config-env, config-hardware, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import inputs.config-hardware.url) # ローカルのhardware-configuration.nix

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users = {
                # ローカルのenv.nixから動的にユーザー名を取得
                ${(import inputs.config-env.url).user or "default-user"} =
                  import ./types/${(import inputs.config-env.url).type or "default"}.nix;
              };
            };
          }

          {
            # ブートローダー設定
            boot.loader.grub.enable = true;
            boot.loader.grub.devices = [ (import inputs.config-env.url).bootDevice or "/dev/sda" ];

            # ネットワーク設定
            networking = {
              hostName = (import inputs.config-env.url).hostname or "nixos";
              defaultGateway = (import inputs.config-env.url).gateway or "192.168.1.1";
              interfaces.eth0.ipv4.addresses = [ {
                address = (import inputs.config-env.url).ipv4Address or "192.168.1.100";
                prefixLength = 24;
              } ];
              nameservers = (import inputs.config-env.url).nameservers or [ "8.8.8.8" ];
              firewall.enable = (import inputs.config-env.url).firewall or false;
              firewall.allowedTCPPorts = (import inputs.config-env.url).allowedPorts or [];
            };

            # ユーザー設定
            users.users."${(import inputs.config-env.url).user or "default-user"}" = {
              isNormalUser = true;
              extraGroups = (import inputs.config-env.url).groups or [];
              initialPassword = (import inputs.config-env.url).password or "default-password";
              openssh.authorizedKeys.keys = (import inputs.config-env.url).authorizedKeys or [];
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
            imports = if (import inputs.config-env.url).gui then [ ./gui-config.nix ] else [];
          }
        ];
      };
    };
  };
}

