{
  description = "evalys - Infrastructure Performance Evaluation Toolkit";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Let nur-kapack use its own pinned nixpkgs so its package set (procset)
    # evaluates cleanly.
    nur-kapack.url = "github:oar-team/nur-kapack";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          # procset is not in nixpkgs; it comes from nur-kapack (built from the
          # gitlab.inria.fr source). It bundles the `intsetwrap` module used by
          # evalys/mstates.py and evalys/pstates.py.
          procset = inputs'.nur-kapack.packages.procset;

          # Build evalys (and pull every Python dependency) with the same
          # interpreter procset was built against, so the closures stay
          # compatible across the two nixpkgs revisions.
          python = procset.pythonModule;
          pyPkgs = python.pkgs;

          evalys = python.pkgs.buildPythonPackage {
            pname = "evalys";
            version = "4.0.7";
            src = ./.;
            pyproject = true;

            build-system = [ pyPkgs.setuptools ];

            dependencies = [
              pyPkgs.pandas
              pyPkgs.matplotlib
              pyPkgs.seaborn
              procset
            ];

            # Tests run from the dev shell / `nix flake check`, not at build time.
            doCheck = false;
            pythonImportsCheck = [ "evalys" ];
          };
        in
        {
          packages.default = evalys;
          packages.evalys = evalys;

          devShells.default = pkgs.mkShell {
            inputsFrom = [ evalys ];
            packages = [
              pyPkgs.pip
              pyPkgs.pytest
              pyPkgs.pytest-cov
              pyPkgs.flake8
              pyPkgs.sphinx
              pyPkgs.build
              pyPkgs.twine
            ];
          };
        };
    };
}
