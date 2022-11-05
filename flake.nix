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
      overlays = [(final: prev: {
        haskell = prev.haskell // {
          packageOverrides = lib.composeExtensions prev.haskell.packageOverrides (final.haskell.lib.packageSourceOverrides {
            hlint = "3.5";
          });
        };
      })];
    };

    inherit (pkgs) lib haskell;

    compiler = "ghc94";

    name = "wb";

    project = devTools:
      let addBuildTools = (lib.trivial.flip haskell.lib.addBuildTools) devTools;
      in haskell.packages.${compiler}.developPackage {
        root = lib.sourceByRegex ./. [ "^package\.yaml$" ".*\.hs" ];
        inherit name;
        returnShellEnv = !(devTools == []);

        source-overrides = {
          vty = "5.37";
          brick = "1.4";
          bimap = "0.5.0";
          text-zipper = "0.12";
        };

        overrides = final: prev: {
          string-qq = haskell.lib.dontCheck prev.string-qq;
          monad-bayes = haskell.lib.doJailbreak (final.callCabal2nix "monad-bayes" inputs.monad-bayes {});
        };

        modifier = (lib.trivial.flip lib.trivial.pipe) [
          addBuildTools
          haskell.lib.dontHaddock
          haskell.lib.enableStaticLibraries
          haskell.lib.justStaticExecutables
          haskell.lib.disableLibraryProfiling
          haskell.lib.disableExecutableProfiling
        ];
      };
  in rec {
    packages = {
      default = packages.wb;

      wb = project [];
    };

    devShells = {
      default = devShells.haskell;

      jupyter = inputs.monad-bayes.devShells.default;
      haskell = project (with haskell.packages.${compiler}; [
        cabal-fmt cabal-install hpack
        haskell-language-server hlint
      ]);
    };
  });
}
