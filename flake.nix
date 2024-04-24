 {
  description =
    "This flake builds the Kubeclarity CLI using Nix's buildGoModule Function.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    kubeclarity-input = {
      type = "github";
      owner = "openclarity";
      repo = "kubeclarity";
      ref = "v2.23.1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, kubeclarity-input }:
    # Use the flake-utils lib to easily create a multi-system flake
    flake-utils.lib.eachDefaultSystem (system:
    let
      version = "2.23.1";
    in
      {
        packages =
          let
            pkgs = import nixpkgs { inherit system; };
            pname = "kubeclarity";
            name = "kubeclarity-${version}";
            isLinux = pkgs.stdenv.isLinux;
            lib = pkgs.lib;
          in
          {
            # Build the kubeclarity package using Nix's buildGoModuleFunction
            kubeclarity = pkgs.buildGoModule {
              inherit version;
              inherit pname;
              inherit name;

              src = kubeclarity-input;

              # If the vendor folder is not checked in, we have to provide a hash for the vendor folder. Nix requires this to ensure the vendor folder is reproducible, and matches what we expect.
              vendorHash = "sha256-JY64fqzNBpo9Jwo8sWsWTVVAO5zzwxwXy0A2bgqJHuU=";

              # Ensure vendor folders are the same between Linux + macOS
              proxyVendor = true;

              nativeBuildInputs = [
                pkgs.pkg-config
              ];

              buildInputs = [] ++ (lib.optionals isLinux [
                pkgs.btrfs-progs
                pkgs.lvm2
              ]);
              
              CGO_ENABLED = "0";

              sourceRoot = "source/cli";

              ldflags = [
                "-s"
                "-w"
                "-X github.com/openclarity/kubeclarity/cli/pkg.GitRevision=${version}"
              ];

              # Move the CLI output and name it kubeclarity
              postInstall = ''
                mv $out/bin/cli $out/bin/kubeclarity
              '';
            };
          };
      }
    );
}