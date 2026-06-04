{
  description = "Sangaku — a proof-carrying computer algebra system, written in Lisp for the Lizard interpreter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # The Lizard interpreter (the engine Sangaku runs on). Sangaku is pure Lisp;
    # Lizard provides the runtime, the trusted kernel, and the standard library.
    lizard = {
      url = "github:hydrastro/lizard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, lizard }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # The Lizard interpreter binary, taken from the lizard flake's default package.
        # If the lizard flake exposes its interpreter under a different attribute, adjust
        # `lizard-bin` accordingly (e.g. lizard.packages.${system}.lizard).
        lizard-bin = lizard.packages.${system}.default or lizard.defaultPackage.${system};

        # Sangaku itself: the Lisp sources, examples, tests, and the run scripts.
        sangaku = pkgs.stdenv.mkDerivation {
          pname = "sangaku";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ lizard-bin ];

          # There is nothing to compile — Sangaku is interpreted Lisp. The build phase
          # runs the golden tests and the example suite against the Lizard interpreter,
          # so a successful build is a passing test run.
          buildPhase = ''
            export SANGAKU_ROOT="$PWD"
            export LIZARD="${lizard-bin}/bin/lizard"
            bash scripts/test.sh
          '';

          installPhase = ''
            mkdir -p "$out/share/sangaku"
            cp -r src examples tests docs scripts "$out/share/sangaku/"
            # A convenience launcher: `sangaku FILE.lisp` loads the prelude (which puts
            # the library on the module path) and then runs FILE.lisp.
            mkdir -p "$out/bin"
            cat > "$out/bin/sangaku" <<EOF
#!${pkgs.bash}/bin/bash
exec ${lizard-bin}/bin/lizard "$out/share/sangaku/src/prelude.lisp" "\$@"
EOF
            chmod +x "$out/bin/sangaku"
          '';

          meta = with pkgs.lib; {
            description = "A proof-carrying computer algebra system in Lisp";
            longDescription = ''
              Sangaku is a computer algebra system in which every positive result carries a
              machine-checkable certificate: a differentiation check for an integral, a
              reduction modulo a Groebner basis for ideal membership, an exact evaluation to
              zero for a solution tuple, or two independent computations agreeing. It runs on
              the Lizard interpreter and its trusted dependent-type kernel.
            '';
            homepage = "https://github.com/hydrastro/sangaku";
            license = licenses.unfree; # set to your chosen license (see LICENSE)
            platforms = platforms.unix;
          };
        };
      in
      {
        packages.default = sangaku;
        packages.sangaku = sangaku;

        # `nix develop` gives you the Lizard interpreter on PATH plus the helper env vars,
        # so you can iterate: `sangaku-run examples/388-definite-integral-theorems.lisp`.
        devShells.default = pkgs.mkShell {
          buildInputs = [ lizard-bin pkgs.bash ];
          shellHook = ''
            export SANGAKU_ROOT="$PWD"
            export LIZARD="${lizard-bin}/bin/lizard"
            sangaku-run () { "$LIZARD" "$SANGAKU_ROOT/src/prelude.lisp" "$@"; }
            export -f sangaku-run
            echo "Sangaku dev shell — Lizard on PATH as: $LIZARD"
            echo "  run a file:   sangaku-run examples/388-definite-integral-theorems.lisp"
            echo "  run tests:    bash scripts/test.sh"
            echo "  run examples: bash scripts/run-examples.sh"
          '';
        };

        # `nix run` runs the example/test suite.
        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "sangaku-check" ''
            export SANGAKU_ROOT="$PWD"
            export LIZARD="${lizard-bin}/bin/lizard"
            exec bash scripts/test.sh
          ''}";
        };
      });
}
