{ # Package set to build the Emacs environment from
emacsPackages
  # Emacs package to use during build
, emacs ? emacsPackages.emacs
  # Your `init.el` file to use for discovering and installing packages
, emacsInitFile
# Additional argument to pass to Emacs or your init file
, emacsArgs ? [ ]
  # Additional files you wish to load prior to executing package discovery
  # Good place to place to call `advice-add` from
, emacsLoadFiles ? [ ]
  # Abort processing if a package not found in `emacsPackages`
  # Setting it to false will result in just skipping an unavailable package
, abortOnNotFound ? true
  #
, lib }:

let
  epkgs = emacsPackages.overrideScope'
    (self: super: { straight = self.callPackage ./straight { }; });

  recipesIFD = epkgs.callPackage ({ stdenv }:
    stdenv.mkDerivation {
      name = "emacs-straight-packages.json";
      buildInputs = [ emacs ];
      dontUnpack = true;
      buildPhase = ":";
      installPhase = ''
        runHook preInstall
        ; TODO/CONTINUE: Overhaul this, replace n-s-get-used-packages and emacsArgs as
        ; used in ./default.nix to run a doomscript (or maybe bin/doom shebang, very similar..)
        ; which dumps everything without hacking into the existing Doom CLI commands.
        ; Once that's done, we can flush and read straight--recipe-cache for most metadata,
        ; and also include the commit revs from doom-packages.
        ;
        ; I expect network activity for fetching the package metadata only,
        ; and then fetchFromGithub/fetchurl/… in Nix using the output of this derivation,
        ; which will be a FOD and is already an IFD. (but will turn into more than a list of packages)
        emacs -q \
              --batch \
              --directory=${epkgs.straight}/share/emacs/site-lisp \
              --load=${./setup.el} \
              ${
                lib.concatMapStringsSep "\n" (f: "--load=${f}") emacsLoadFiles
              } \
              --eval="(nix-straight-get-used-packages \"${emacsInitFile}\" \"$out\")" \
              ${lib.escapeShellArgs emacsArgs}
        runHook postInstall
      '';
    }) { };

  # It's up to the user to importJSON recipesIFD first, unfortunately,
  # since I don't want to mess with .overrideAttrs.
  packageList = recipes':
    map (x:
      if epkgs ? "${x}" then
        epkgs.${x}
      else if abortOnNotFound then
        abort "Package not available: ${x}"
      else
        (lib.warn "Package not available: ${x}") null) recipes';

  emacsEnv = epkgs.callPackage ({ stdenv, writeScript, ... }:
    { packages, straightDir }:
    let
      expandDependencies = packages:
        let
          withDeps = p:
            map (x:
              if x == null then
                [ ]
              else
                [ x ] ++ withDeps x.propagatedBuildInputs) (lib.flatten p);
        in (lib.unique
          (lib.filter (d: d ? ename) (lib.flatten (withDeps packages))));

      install = repo: packages:
        let
          installPkg = repo: pkg: (''
            REPO=${repo}
            psrc=(${pkg}/share/emacs/*/*/${pkg.ename}*)
            if [[ ! -d $psrc ]]; then
              elpa_path=(${pkg}/share/emacs/site-lisp/elpa/*)
              if [[ -d $elpa_path ]]; then
                ln -snf $elpa_path $REPO/${pkg.ename}
              else
                ln -snf ${pkg}/share/emacs/site-lisp $REPO/${pkg.ename}
              fi
            else
              ln -snf $psrc $REPO/${pkg.ename}
            fi
            ${ # TODO get rid of this junk
            lib.optionalString
            ((pkg.src ? meta) && (pkg.src.meta ? homepage)) ''
              if [[ ! -d $REPO/${baseNameOf pkg.src.meta.homepage} ]]; then
                ln -snf $psrc $REPO/${baseNameOf pkg.src.meta.homepage}
              fi
            ''}
          '');
        in writeScript "install-repo" ''
          mkdir -p ${repo}
          ${(lib.concatMapStringsSep "\n" (installPkg repo)
            (expandDependencies packages))}
        '';
    in stdenv.mkDerivation {
      name = "straight-emacs-env";
      buildPhase = ":";
      buildInputs = [ emacs ];
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        ${(install "${straightDir}/repos" packages)}
        emacs -q \
              --batch \
              --directory=${epkgs.straight}/share/emacs/site-lisp \
              --load=${./setup.el} \
              ${
                lib.concatMapStringsSep "\n" (f: "--load=${f}") emacsLoadFiles
              } \
              --eval="(nix-straight-build-packages \"${emacsInitFile}\")" ${
                lib.escapeShellArgs emacsArgs
              } \
              || (cat $out/logs/cli.doom.*.error 1>&2 && false) # print a proper stacktrace if things fail

        runHook postInstall
      '';
    }) { };

in {
  /* Final environment (.emacs.d) with the populated `straight`` repository

     The required packages can be acquired from a call to
     `packageList` function.

     Type: emacsEnv :: { straightDir :: string, packages :: [derivation] } -> derivation

     Example:
       emacsEnv {
         straightDir = "$out/straight";
         packages = packageList (super: { ... } );
       };
  */
  inherit emacsEnv;
  /* Package list inferred from processing `emacsInitFile`

     The passed function will be called via an `overrideAttrs
     call on the`underlying derivation.

     Type: packageList :: attrs -> attrs -> derivation

     Example:
       packageList (super: {
         src = ...;
         preInstall = ''
           ...
         ''
       });
  */
  inherit packageList;

  /* Derivation containing a JSON structure of package recipes

     These are the packages needed to be populated in the
     `straight` repository.

     Type: recipesIFD :: TODO
  */
  inherit recipesIFD;
}
