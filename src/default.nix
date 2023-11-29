{ # The files would be going to ~/.config/doom (~/.doom.d)
doomPrivateDir
/* A Doom configuration directory from which to build the Emacs package environment.

   Can be used, for instance, to prevent rebuilding the Emacs environment
   each time the `config.el` changes.

   Can be provided as a directory or derivation. If not given, package
   environment is built against `doomPrivateDir`.

   Example:
     doomPackageDir = pkgs.linkFarm "my-doom-packages" [
       # straight needs a (possibly empty) `config.el` file to build
       { name = "config.el"; path = pkgs.emptyFile; }
       { name = "init.el"; path = ./doom.d/init.el; }
       {
         name = "packages.el";
         path = pkgs.writeText "packages.el" "(package! inheritenv)";
       }
       { name = "modules"; path = ./my-doom-module; }
     ];
*/
, doomPackageDir ? doomPrivateDir
  /* Extra packages to install

     Useful for non-emacs packages containing emacs bindings (e.g.
     mu4e).

     Example:
       extraPackages = epkgs: [ pkgs.mu ];

     TODO: Is this still necessary? Behaviour may be misleading.
  */
, extraPackages ? epkgs:
  [ ]
  /* Extra configuration to source during initialization

     Use this to refer other nix derivations.

     Example:
       extraConfig = ''
         (setq mu4e-mu-binary = "${pkgs.mu}/bin/mu")
       '';
  */
, extraConfig ? ""
  /* Package set to install emacs and dependent packages from

     Only used to get emacs package, if `bundledPackages` is set.
  */
, emacsPackages
/* Overlay to customize emacs (elisp) dependencies

   See overrides.nix for addition examples.

   Example:
     emacsPackagesOverlay = final: prev: {
       magit-delta = super.magit-delta.overrideAttrs (esuper: {
         buildInputs = esuper.buildInputs ++ [ pkgs.git ];
       });
     };
*/
, emacsPackagesOverlay ? final: prev:
  { }
  /* Use bundled revision of github.com/nix-community/emacs-overlay
     as `emacsPackages`.
  */
  # , bundledPackages ? true # FIXME: non-bundled is unsupported currently
  /* Override dependency versions

     Handy for testing out updated dependencies without publishing
     a new version of them.

     Type: dependencyOverrides :: attrset -> either path derivation

     Example:
       dependencyOverrides = {
         "emacs-overlay" = fetchFromGitHub { owner = /* ...*\/; };
       };
  */
, dependencyOverrides ? { }
  #
, lib, pkgs, stdenv, buildEnv, makeWrapper, runCommand, fetchFromGitHub
, writeShellScript, writeShellScriptBin, writeTextDir }:

assert (lib.assertMsg ((builtins.isPath doomPrivateDir)
  || (lib.isDerivation doomPrivateDir) || (lib.isStorePath doomPrivateDir))
  "doomPrivateDir must be either a path, a derivation or a stringified store path");

let
  isEmacs29 = lib.versionAtLeast emacsPackages.emacs.version "29";
  flake = (import (let lock = with builtins; fromJSON (readFile ../flake.lock);
  in builtins.fetchTarball {
    url =
      "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  }) { src = ./..; }).defaultNix;
  lock = p:
    if dependencyOverrides ? ${p} then
      dependencyOverrides.${p}
    else
      flake.inputs.${p};

  #
  # Stage 1.1: prepare source for byte-compilation
  #
  doomSrc = stdenv.mkDerivation {
    name = "doom-src";
    src = lock "doom-emacs";
    phases = [ "unpackPhase" "patchPhase" "installPhase" ];
    patches = [ ./patches/fix-paths.patch ];
    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';
  };

  fmt = {
    reset = "\\\\033[0m";
    bold = "\\\\033[1m";
    red = "\\\\033[31m";
    green = "\\\\033[32m";
  };

  #
  # Stage 1.2: Prepare a solid emacsPackages environment

  # Bundled version of `emacs-overlay`
  emacs-overlay = import (lock "emacs-overlay") pkgs pkgs;

  # Packages we need to get the default doom configuration run
  overrides = self: super:
    (pkgs.callPackage ./overrides.nix { inherit lock; } self super)
    // (emacsPackagesOverlay self super);

  epkgs = (emacs-overlay.emacsPackagesFor emacsPackages.emacs).overrideScope'
    overrides;

  #
  # Stage 2.1: Extract recipes from Doom
  #
  straight-env = pkgs.callPackage ./straight.nix {
    emacsPackages = epkgs;
    emacs = emacsPackages.emacsWithPackages extraPackages;
    emacsLoadFiles = [ ./advice.el ];
    emacsArgs = [ "--" "install" "--no-hooks" "--no-fonts" "--no-env" ];

    # Need to reference a store path here, as byte-compilation will bake-in
    # absolute path to source files.
    emacsInitFile = "${doomSrc}/bin/doom";
  };

  # I don't know why but byte-compilation somehow triggers Emacs to look for
  # the git executable. It does not seem to be executed though...
  #
  # TODO: Remove me and bear the fallout.
  gitStub = writeShellScriptBin "git" ''
    >&2 echo "Executing git is not allowed; command line:" "$@"
    exit 127
  '';

  # nix-instantiate --show-trace --json --eval --strict --expr 'with import <nixpkgs> {}; (callPackage ./. { doomPrivateDir = ./test/doom.d ;}).passthru.straightRecipes' | jq .
  straightRecipes = lib.importJSON (straight-env.recipesIFD.overrideAttrs
    (super: {
      phases = [ "installPhase" ];
      nativeBuildInputs = [ gitStub ];
      preInstall = ''
        export DOOMDIR=${doomPackageDir}
        export DOOMLOCALDIR=$(mktemp -d)/local/
      '';
    }));

  straightPackages = straight-env.packageList straightRecipes;

  #
  # Stage 2.2: install dependencies and byte-compile prepared source
  doomLocal = (straight-env.emacsEnv {
    packages = straightPackages;
    straightDir = "$DOOMLOCALDIR/straight";
  }).overrideAttrs (super: {
    phases = [ "installPhase" ];
    nativeBuildInputs = [ gitStub ];
    preInstall = ''
      export DOOMDIR=${doomPackageDir}
      export DOOMLOCALDIR=$out/

      # Create a bogus $HOME directory because gccEmacs is known to require
      # an existing home directory because the async worker process don't
      # fully respect the value of 'comp-eln-load-path'.
      export HOME=$(mktemp -d)
    '';
    postInstall = ''
      # If gccEmacs or anything would write in $HOME, fail the build.
      if [[ -z "$(find $HOME -maxdepth 0 -empty)" ]]; then
        printf "${fmt.red}${fmt.bold}ERROR:${fmt.reset} "
        printf "${fmt.red}doom-emacs build resulted in files being written in "'$HOME'" of the build sandbox.\n"
        printf "Contents of "'$HOME'":\n"
        find $HOME
        printf ${fmt.reset}
        exit 33
      fi
    '';
  });

  #
  # Stage 3: do additional fixups to refer compiled files in the store
  # and additional files in the users' home
  #
  doom-emacs = stdenv.mkDerivation rec {
    name = "doom-emacs";
    src = doomSrc;

    patches = [ ./patches/nix-integration.patch ];

    buildPhase = ''
      # Remove the windows wrapper for the CLI so the build doesn't fail
      rm bin/doom.cmd
      patchShebangs bin
    '';
    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';
  };

  # Stage 4: `extraConfig` is merged into private configuration
  doomDir = runCommand "doom-private" {
    inherit extraConfig;
    passAsFile = [ "extraConfig" ];
  } ''
    mkdir -p $out
    cp -rL ${doomPrivateDir}/* $out
    chmod u+w $out/config.el
    cat $extraConfigPath > $out/config.extra.el
    cat > $out/config.el << EOF
    (load "${./patches/doom-modeline-workarounds.el}")
    (load "${doomPrivateDir}/config.el")
    (load "$out/config.extra.el")
    EOF
  '';

  #
  # Stage 5: catch-all wrapper capable to run doom-emacs even
  # without installing ~/.emacs.d
  #
  emacs' = let
    load-config-from-site = writeTextDir "share/emacs/site-lisp/default.el" ''
      (message "doom-emacs is not placed in `doom-private-dir', loading from `site-lisp'")
      ${ # TODO: remove once Emacs 29+ is released and commonly available
      lib.optionalString (!isEmacs29) ''
        (load "${doom-emacs}/early-init.el")
      ''}
      (load "${doom-emacs}/lisp/doom.el")
      (load "${doom-emacs}/lisp/doom-start.el")
      (load "${./patches/info-workarounds.el}")
    '';
  in (emacsPackages.emacsWithPackages (epkgs: [ load-config-from-site ]));

  #
  # Stage 6.1: create a `emacs.d` dir to be loaded using `--init-directory` flag from Emacs 29+
  # this will allow proper usage of `early-init.el`, fixing FOUC issues and improving
  # startup performance
  #
  emacs-dir = runCommand "emacs-dir" { } ''
    mkdir -p $out
    cat > $out/early-init.el << EOF
    (load "${doom-emacs}/early-init.el")
    EOF
    cat > $out/init.el << EOF
    (load "default.el")
    EOF
  '';

  build-summary = writeShellScript "build-summary" ''
    printf "\n${fmt.green}Successfully built nix-doom-emacs!${fmt.reset}\n"
    printf "${fmt.bold}  ==> doom-emacs is installed to ${doom-emacs}${fmt.reset}\n"
    printf "${fmt.bold}  ==> private configuration is installed to ${doomDir}${fmt.reset}\n"
    printf "${fmt.bold}  ==> Dependencies are installed to ${doomLocal}${fmt.reset}\n"
  '';

  #
  # Stage 6.2: Wrap and fixup Emacs binaries, including the Doom environment
  emacs = emacs'.overrideAttrs (esuper:
    let
      # `--init-directory` is supported by Emacs 29+ only
      initDirArgs = lib.optionalString isEmacs29 ''
        if [[ $(basename $1) == emacs ]] || [[ $(basename $1) == emacs-* ]]; then
          wrapArgs+=(--add-flags '--init-directory ${emacs-dir}')
        fi
      '';
      cmd = ''
        wrapEmacs() {
            local -a wrapArgs=(
                --set NIX_DOOM_EMACS_BINARY $1
                --set __DEBUG_doom_emacs_DIR ${doom-emacs}
                --set __DEBUG_doomLocal_DIR ${doomLocal}
                --set-default DOOMDIR ${doomDir}
                --set-default DOOMLOCALDIR ${doomLocal}
            )
            ${initDirArgs}

            wrapProgram $1 "''${wrapArgs[@]}"
        }

        for prog in $out/bin/*; do
            wrapEmacs $prog
        done

        # Doom comes with some CLIs (org-tangle, org-capture, doom)
        for prog in ${doom-emacs}/bin/*; do
            makeWrapper $prog $out/bin/"$(basename $prog)" --prefix PATH : $out/bin
        done

        if [[ -e $out/Applications ]]; then
          wrapEmacs "$out/Applications/Emacs.app/Contents/MacOS/Emacs"
        fi
        # emacsWithPackages assumes share/emacs/site-lisp/subdirs.el
        # exists, but doesn't pass it along.  When home-manager calls
        # emacsWithPackages again on this derivation, it fails due to
        # a dangling link to subdirs.el.
        # https://github.com/NixOS/nixpkgs/issues/66706
        rm -rf $out/share
        ln -s ${esuper.emacs}/share $out
        ${build-summary}
      '';
    in if esuper ? buildCommand then {
      buildCommand = esuper.buildCommand + cmd;
    } else if esuper ? installPhase then {
      installPhase = esuper.installPhase + cmd;
    } else
      abort "emacsWithPackages uses unknown derivation type");
in emacs // { passthru = { inherit straightPackages straightRecipes; }; }