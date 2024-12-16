{
  description = "NixOS Configuration with Home Manager (External)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    config-env.url = "path:/etc/nixos/env.nix";
    config-hardware.url = "path:/etc/nixos/hardware-configuration.nix";
  };

  outputs = inputs@{ nixpkgs, home-manager, config-env, config-hardware, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import config-hardware.path)

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users = {
                ${(import config-env.path).user or "default"} =
                  import ./types/"${(import config-env.path).type or "default"}.nix";
              };
            };
          }

          {
            # Boot Loader Config
            boot.loader.grub.enable = true;
            boot.loader.grub.devices = [ (import config-env.path).bootDevice or "/dev/sda" ];

            # Network Config
            networking = {
              hostName = (import config-env.path).hostname or "nixos";
              defaultGateway = (import config-env.path).gateway or "192.168.1.1";
              interfaces.eth0.ipv4.addresses = [ {
                address = (import config-env.path).ipv4Address or "192.168.1.100";
                prefixLength = 24;
              } ];
              nameservers = (import config-env.path).nameservers or [ "8.8.8.8" ];
              firewall.enable = (import config-env.path).firewall or false;
              firewall.allowedTCPPorts = (import config-env.path).allowedPorts or [];
            };

            # User Config
            users.users."${(import config-env.path).user or "default-user"}" = {
              isNormalUser = true;
              extraGroups = (import config-env.path).groups or [];
              initialPassword = (import config-env.path).password or "default-password";
              openssh.authorizedKeys.keys = (import config-env.path).authorizedKeys or [];
            };

            # sudo Config
            security.sudo.extraRules = [
              {
                groups = ["wheel"];
                commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
              }
            ];

            # SSH Config
            services.openssh.enable = true;

            # Docker Config
            virtualisation.docker.enable = true;

            # GUI Config
            imports = if (import config-env.path).gui then [ ./gui-config.nix ] else [];
          }
        ];
      };
    };
  };
}

