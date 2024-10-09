{
  description = "Scholarly Software";

  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        ruby = inputs.nixpkgs-ruby.lib.packageFromRubyVersionFile {
          inherit system;
          file = ./.ruby-version;
        };

        gemHome = ".gem/${builtins.baseNameOf ruby}";
        overlays = [
          (self: super: { inherit ruby; })
        ];

        pkgs = import inputs.nixpkgs { inherit overlays system; };
      in
      {
        devShell = pkgs.mkShell {
          env = {
            GEM_HOME = gemHome;
            GEM_PATH = gemHome;
          };
          shellHook = ''
            export PATH=$PATH:${gemHome}/bin
          '';
          buildInputs = (
            with pkgs;
            [
              bundler.ruby
              bundler
            ]
          );
        };
      }
    );
}
