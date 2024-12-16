{
  description = "NixOS Configuration with Home Manager (External)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: { config, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # `config.hardwareConfig` を参照
          config.hardwareConfig

          # Home Manager の設定
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users = {
                ${config.env.user or "default-user"} = import ./types/"${config.env.type or "default"}.nix";
              };
            };
          }

          # その他の設定
          {
            boot.loader.grub.enable = true;
            boot.loader.grub.devices = [ config.env.bootDevice or "/dev/sda" ];

            networking = {
              hostName = config.env.hostname or "nixos";
              defaultGateway = config.env.gateway or "192.168.1.1";
              interfaces.eth0.ipv4.addresses = [ {
                address = config.env.ipv4Address or "192.168.1.100";
                prefixLength = 24;
              } ];
              nameservers = config.env.nameservers or [ "8.8.8.8" ];
              firewall.enable = config.env.firewall or false;
              firewall.allowedTCPPorts = config.env.allowedPorts or [];
            };

            services.openssh.enable = true;
            virtualisation.docker.enable = true;

            # GUI 設定
            imports = if config.env.gui then [ ./gui-config.nix ] else [];
          }
        ];
      };
    };
  };
}

