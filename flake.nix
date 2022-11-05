{
  nixConfig = {
    extra-substituters = [
      "https://tweag-monad-bayes.cachix.org"
      "https://tweag-wasm.cachix.org"
    ];
    extra-trusted-public-keys = [
      "tweag-monad-bayes.cachix.org-1:tmmTZ+WvtUMpYWD4LAkfSuNKqSuJyL3N8ZVm/qYtqdc="
      "tweag-wasm.cachix.org-1:Eu5eBNIJvleiWMEzRBmH3/fzA6a604Umt4lZguKtAU4="
    ];
  };
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    monad-bayes.url = github:tweag/monad-bayes;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, ... }@inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = {};
      overlays = [];
    };

    inherit (pkgs) lib haskell;

    compiler = "ghc94";

    name = "wb";

    source-overrides = {
      vty = "5.37";
      brick = "1.4";
      bimap = "0.5.0";
      text-zipper = "0.12";
      hlint = "3.5";
    };

    overrides = final: prev: {
      string-qq = haskell.lib.dontCheck prev.string-qq;
      monad-bayes = haskell.lib.doJailbreak (final.callCabal2nix "monad-bayes" inputs.monad-bayes {});
    };


    hp = haskell.packages.${compiler}.extend
      (lib.composeExtensions
        (haskell.lib.packageSourceOverrides source-overrides)
        overrides);

    project = hp.callCabal2nixWithOptions name (lib.sourceByRegex ./. [ "^package\.yaml$" ".*\.hs" ]) "" {};
  in rec {
    packages = {
      default = packages.wb;

      wb = project;
    };

    devShells = {
      default = devShells.haskell;

      jupyter = inputs.monad-bayes.devShells.default;
      haskell = (hp.extend (_: _: { inherit (packages) wb; })).shellFor {
        packages = p: [ p.wb ];
        withHoogle = true;
        nativeBuildInputs = with hp; [
          cabal-install hpack hlint
          haskell-language-server
        ];
      };
    };
  });
}
