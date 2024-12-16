{
  description = "NixOS Configuration with Home Manager (External)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # ローカルのenv.nixとhardware-configuration.nixを直接読み込む
          (import /etc/nixos/hardware-configuration.nix)

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users = {
                # env.nixの値を利用
                ${(import /etc/nixos/env.nix).user or "default-user"} = import ./types/${(import /etc/nixos/env.nix).type or "default"}.nix;
              };
            };
          }

          {
            boot.loader.grub.enable = true;
            boot.loader.grub.devices = [ (import /etc/nixos/env.nix).bootDevice or "/dev/sda" ];

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

            services.openssh.enable = true;
            virtualisation.docker.enable = true;
          }
        ];
      };
    };
  };
}

