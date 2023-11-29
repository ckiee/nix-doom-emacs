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
        # TODO/CONTINUE: Overhaul this, replace n-s-get-used-packages and emacsArgs as
        # used in ./default.nix to instead run a doomscript (or maybe bin/doom shebang, very similar..)
        # which dumps everything without hacking into the existing Doom CLI commands.
        # Once that's done, we can flush and read straight--recipe-cache for most metadata,
        # and also include the commit revs from doom-packages.
        #
        # I expect network activity for fetching the package metadata only,
        # and then fetchFromGithub/fetchurl/… in Nix using the output of this derivation,
        # which will be a FOD and is already an IFD. (but will turn into more than a list of packages)
        #
        # Appendix, on a nix-shell'd imperative doom emacs after evaluating (straight-normalize-all)
        # and maybe some others:
        # (json-encode doom-packages) ; "{\"use-package\":{\"modules\":{\"config\":\"use-package\"},\"pin\":\"a6e856418d2ebd053b34e0ab2fda328abeba731c\"},\"auto-minor-mode\":{\"modules\":{\"core\":null},\"pin\":\"17cfa1b54800fdef2975c0c0531dad34846a5065\"},\"gcmh\":{\"modules\":{\"core\":null},\"pin\":\"0089f9c3a6d4e9a310d0791cf6fa8f35642ecfd9\"},\"explain-pause-mode\":{\"modules\":{\"core\":null},\"recipe\":{\"host\":\"github\",\"repo\":\"lastquestion/explain-pause-mode\"},\"pin\":\"2356c8c3639cbeeb9751744dbe737267849b4b51\"},\"straight\":{\"modules\":{\"core\":null},\"type\":\"core\",\"recipe\":{\"host\":\"github\",\"repo\":\"radian-software/straight.el\",\"branch\":\"develop\",\"local-repo\":\"straight.el\",\"files\":[\"straight*.el\"]},\"pin\":\"5e84c4e2cd8ca79560477782ee4c9e5187725def\"},\"all-the-icons\":{\"modules\":{\"core\":null},\"pin\":\"be9d5dcda9c892e8ca1535e288620eec075eb0be\"},\"nerd-icons\":{\"modules\":{\"core\":null},\"pin\":\"619a0382d2e159f3142c4200fe4cfc2e89247ef1\"},\"hide-mode-line\":{\"modules\":{\"core\":null},\"pin\":\"bc5d293576c5e08c29e694078b96a5ed85631942\"},\"highlight-numbers\":{\"modules\":{\"core\":null},\"pin\":\"8b4744c7f46c72b1d3d599d4fb75ef8183dee307\"},\"rainbow-delimiters\":{\"modules\":{\"core\":null},\"pin\":\"f40ece58df8b2f0fb6c8576b527755a552a5e763\"},\"restart-emacs\":{\"modules\":{\"core\":null},\"pin\":\"1607da2bc657fe05ae01f7fdf26f716eafead02c\"},\"better-jumper\":{\"modules\":{\"core\":null},\"pin\":\"47622213783ece37d5337dc28d33b530540fc319\"},\"dtrt-indent\":{\"modules\":{\"core\":null},\"pin\":\"e0630f74f915c6cded05f76f66d66e540fcc37c3\"},\"helpful\":{\"modules\":{\"core\":null},\"pin\":\"66ba816b26b68dd7df08e86f8b96eaae16c8d6a2\"},\"pcre2el\":{\"modules\":{\"core\":null},\"pin\":\"018531ba0cf8e2b28d1108136a0e031b6a45f1c1\"},\"smartparens\":{\"modules\":{\"core\":null},\"pin\":\"79a338db115f441cd47bb91e6f75816c5e78a772\"},\"ws-butler\":{\"modules\":{\"core\":null},\"recipe\":{\"host\":\"github\",\"repo\":\"hlissner/ws-butler\",\"flavor\":\"melpa\"},\"pin\":\"572a10c11b6cb88293de48acbb59a059d36f9ba5\"},\"projectile\":{\"modules\":{\"core\":null},\"pin\":\"971cd5c4f25ff1f84ab7e8337ffc7f89f67a1b52\"},\"project\":{\"modules\":{\"core\":null},\"pin\":\"ce140cdb70138a4938c999d4606a52dbeced4676\"},\"general\":{\"modules\":{\"core\":null},\"pin\":\"833dea2c4a60e06fcd552b653dfc8960935c9fb4\"},\"which-key\":{\"modules\":{\"core\":null},\"pin\":\"4d20bc852545a2e602f59084a630f888542052b1\"},\"compat\":{\"modules\":{\"core\":null},\"recipe\":{\"host\":\"github\",\"repo\":\"emacs-compat/compat\",\"files\":[\"*\",{\"exclude\":\".git\"}]},\"pin\":\"ecf53005abf6f0325d14e0e024222e22e982c8dd\"},\"company\":{\"modules\":{\"completion\":\"company\"},\"pin\":\"2ca3e29abf87392714bc2b26e50e1c0f4b9f4e2c\"},\"company-dict\":{\"modules\":{\"completion\":\"company\"},\"pin\":\"cd7b8394f6014c57897f65d335d6b2bd65dab1f4\"},\"vertico\":{\"modules\":{\"completion\":\"vertico\"},\"recipe\":{\"host\":\"github\",\"repo\":\"minad/vertico\",\"files\":[\"*.el\",\"extensions/*.el\"],\"flavor\":\"melpa\"},\"pin\":\"a28370d07f35c5387c7a9ec2e5b67f0d4598058d\"},\"orderless\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"e6784026717a8a6a7dcd0bf31fd3414f148c542e\"},\"consult\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"fe49dedd71802ff97be7b89f1ec4bd61b98c2b13\"},\"consult-dir\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"ed8f0874d26f10f5c5b181ab9f2cf4107df8a0eb\"},\"consult-flycheck\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"3f2a7c17cc2fe64e0c07e3bf90e33c885c0d7062\"},\"embark\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"9a44418c349e41020cdc5ad1bd21e8c77a429062\"},\"embark-consult\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"9a44418c349e41020cdc5ad1bd21e8c77a429062\"},\"marginalia\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"866e50aee4f066b0903752c69b33e9b7cab93f97\"},\"wgrep\":{\"modules\":{\"completion\":\"vertico\"},\"pin\":\"3132abd3750b8c87cbcf6942db952acfab5edccd\"},\"doom-themes\":{\"modules\":{\"ui\":\"doom\"},\"pin\":\"4aee1f5a0e54552669f747aa7c25e6027e73d76d\"},\"solaire-mode\":{\"modules\":{\"ui\":\"doom\"},\"pin\":\"8af65fbdc50b25ed3214da949b8a484527c7cc14\"},\"hl-todo\":{\"modules\":{\"ui\":\"hl-todo\"},\"pin\":\"70ce48470c85f1441de2c9428a240c3287995846\"},\"doom-modeline\":{\"modules\":{\"ui\":\"modeline\"},\"pin\":\"93f240f7a0bf35511cfc0a8dd75786744b4bcf77\"},\"anzu\":{\"modules\":{\"ui\":\"modeline\"},\"pin\":\"5abb37455ea44fa401d5f4c1bdc58adb2448db67\"},\"evil-anzu\":{\"modules\":{\"ui\":\"modeline\"},\"pin\":\"d1e98ee6976437164627542909a25c6946497899\"},\"evil-goggles\":{\"modules\":{\"ui\":\"ophints\"},\"pin\":\"0070c9d8447e1696f8713d0c13ff64ef0979d580\"},\"git-gutter-fringe\":{\"modules\":{\"ui\":\"vc-gutter\"},\"pin\":\"648cb5b57faec55711803cdc9434e55a733c3eba\"},\"vi-tilde-fringe\":{\"modules\":{\"ui\":\"vi-tilde-fringe\"},\"pin\":\"f1597a8d54535bb1d84b442577b2024e6f910308\"},\"persp-mode\":{\"modules\":{\"ui\":\"workspaces\"},\"pin\":\"df95ea710e2a72f7a88293b72137acb0ca024d90\"},\"evil\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"5fc16776c5eb00c956ec7e9d83facb6a38dd868d\"},\"evil-args\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"2671071a4a57eaee7cc8c27b9e4b6fc60fd2ccd3\"},\"evil-easymotion\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"f96c2ed38ddc07908db7c3c11bcd6285a3e8c2e9\"},\"evil-embrace\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"3081d37811b6a3dfaaf01d578c7ab7a746c6064d\"},\"evil-escape\":{\"modules\":{\"editor\":\"evil\"},\"recipe\":{\"host\":\"github\",\"repo\":\"hlissner/evil-escape\",\"flavor\":\"melpa\"},\"pin\":\"819f1ee1cf3f69a1ae920e6004f2c0baeebbe077\"},\"evil-exchange\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"5f0a2d41434c17c6fb02e4f744043775de1c63a2\"},\"evil-indent-plus\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"b4dacbfdb57f474f798bfbf5026d434d549eb65c\"},\"evil-lion\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"1e838a53b8f18a3c8bdf3e952186abc2ee9cb98e\"},\"evil-nerd-commenter\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"3b197a2b559b06a7cf39978704b196f53dac802a\"},\"evil-numbers\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"7a1b62afc12da2b582bf84d722e7b10ca8b97065\"},\"evil-snipe\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"c2108d3932fcd2f75ac3e48250d6badd668f5b4f\"},\"evil-surround\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"8fad8540c490d94a820004f227552ca08e3e3857\"},\"evil-textobj-anyblock\":{\"modules\":{\"editor\":\"evil\"},\"recipe\":{\"host\":\"github\",\"repo\":\"willghatch/evil-textobj-anyblock\",\"branch\":\"fix-inner-block\",\"flavor\":\"melpa\"},\"pin\":\"29280cd71a05429364cdceef2ff595ae8afade4d\"},\"evil-traces\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"82e8a7b4213aed140f6eb5f2cc33a09bb5587166\"},\"evil-visualstar\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"06c053d8f7381f91c53311b1234872ca96ced752\"},\"exato\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"aee7af7b7a0e7551478f453d1de7d5b9cb2e06c4\"},\"evil-quick-diff\":{\"modules\":{\"editor\":\"evil\"},\"recipe\":{\"host\":\"github\",\"repo\":\"rgrinberg/evil-quick-diff\"},\"pin\":\"69c883720b30a892c63bc89f49d4f0e8b8028908\"},\"evil-collection\":{\"modules\":{\"editor\":\"evil\"},\"pin\":\"8be4b75c86bc637dbcd14be7522d6da06df1747e\"},\"yasnippet\":{\"modules\":{\"editor\":\"file-templates\",\"editor\":\"snippets\"},\"pin\":\"76e1eee654ea9479ba1441f9c17567694e6a2096\"},\"hideshow\":{\"modules\":{\"editor\":\"fold\"},\"ignore\":true},\"vimish-fold\":{\"modules\":{\"editor\":\"fold\"},\"pin\":\"a6501cbfe3db791f9ca17fd986c7202a87f3adb8\"},\"evil-vimish-fold\":{\"modules\":{\"editor\":\"fold\"},\"pin\":\"b6e0e6b91b8cd047e80debef1a536d9d49eef31a\"},\"auto-yasnippet\":{\"modules\":{\"editor\":\"snippets\"},\"pin\":\"6a9e406d0d7f9dfd6dff7647f358cb05a0b1637e\"},\"doom-snippets\":{\"modules\":{\"editor\":\"snippets\"},\"recipe\":{\"host\":\"github\",\"repo\":\"doomemacs/snippets\",\"files\":{\"defaults\":\"*\"}},\"pin\":\"d490cba6d762e69b483be308bc387c1f785742f0\"},\"diredfl\":{\"modules\":{\"emacs\":\"dired\"},\"pin\":\"f9140b2c42151dca669003d685c9f079b2e3dc37\"},\"dired-git-info\":{\"modules\":{\"emacs\":\"dired\"},\"pin\":\"9461476a28a5fec0784260f6e318237c662c3430\"},\"dired-rsync\":{\"modules\":{\"emacs\":\"dired\"},\"pin\":\"7940d9154d0a908693999b0e1ea351a6d365c93d\"},\"fd-dired\":{\"modules\":{\"emacs\":\"dired\"},\"pin\":\"458464771bb220b6eb87ccfd4c985c436e57dc7e\"},\"undo-fu\":{\"modules\":{\"emacs\":\"undo\"},\"pin\":\"0e74116fd5c7797811a91ba4eadef50d67523eb6\"},\"undo-fu-session\":{\"modules\":{\"emacs\":\"undo\"},\"pin\":\"a6c4f73bc22401fd36e0f2fd4fe058bb28566d84\"},\"vundo\":{\"modules\":{\"emacs\":\"undo\"},\"pin\":\"24271862a2f746be038306eafe20f5eff55c4566\"},\"vc\":{\"modules\":{\"emacs\":\"vc\"},\"ignore\":true},\"vc-annotate\":{\"modules\":{\"emacs\":\"vc\"},\"ignore\":true},\"smerge-mode\":{\"modules\":{\"emacs\":\"vc\"},\"ignore\":true},\"browse-at-remote\":{\"modules\":{\"emacs\":\"vc\"},\"pin\":\"c020975a891438e278ad1855213d4f3d62c9fccb\"},\"git-commit\":{\"modules\":{\"emacs\":\"vc\"},\"pin\":\"48818355728c48d986d74dde8b1e9fba25f0fd53\"},\"git-timemachine\":{\"modules\":{\"emacs\":\"vc\"},\"recipe\":{\"host\":\"github\",\"repo\":\"emacsmirror/git-timemachine\",\"flavor\":\"melpa\"},\"pin\":\"d8ffd0d7cc4ab3dd7de494c9ea36dfd99e2744fa\"},\"git-modes\":{\"modules\":{\"emacs\":\"vc\"},\"pin\":\"f0a0154bf48dd1c0c587596cf4cfd3c90f673a05\"},\"flycheck\":{\"modules\":{\"checkers\":\"syntax\"},\"pin\":\"784f184cdd9f9cb4e3dbb997c09d93e954142842\"},\"flycheck-popup-tip\":{\"modules\":{\"checkers\":\"syntax\"},\"pin\":\"ef86aad907f27ca076859d8d9416f4f7727619c6\"},\"quickrun\":{\"modules\":{\"tools\":\"eval\"},\"pin\":\"6f963189305e8311c8193ba774f4244eb1315f57\"},\"eros\":{\"modules\":{\"tools\":\"eval\"},\"pin\":\"a9a92bdc6be0521a6a06eb464be55ed61946639c\"},\"dumb-jump\":{\"modules\":{\"tools\":\"lookup\"},\"pin\":\"d9503c157ab88f0ed2fa1301aeb57e95ac564760\"},\"request\":{\"modules\":{\"tools\":\"lookup\"},\"pin\":\"01e338c335c07e4407239619e57361944a82cb8a\"},\"magit\":{\"modules\":{\"tools\":\"magit\"},\"pin\":\"48818355728c48d986d74dde8b1e9fba25f0fd53\"},\"magit-todos\":{\"modules\":{\"tools\":\"magit\"},\"pin\":\"cadf29d1cc410c71a0020c7f83999d9f61721b90\"},\"elisp-mode\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"ignore\":true},\"highlight-quoted\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"24103478158cd19fbcfb4339a3f1fa1f054f1469\"},\"macrostep\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"0b04a89f698c335c9ea492553470a8d45c113edd\"},\"overseer\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"02d49f582e80e36b4334c9187801c5ecfb027789\"},\"elisp-def\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"1d2e88a232ec16bce036b49577c4d4d96035f9f7\"},\"elisp-demos\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"8d0cd806b109076e6c4383edf59dbab9435dc5dc\"},\"flycheck-package\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"3a6aaed29ff61418c48c0251e1432c30748ae739\"},\"flycheck-cask\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"4b2ede6362ded4a45678dfbef1876faa42edbd58\"},\"buttercup\":{\"modules\":{\"lang\":\"emacs-lisp\"},\"pin\":\"30c703d215b075aaede936a2c424f65b5f7b6391\"},\"markdown-mode\":{\"modules\":{\"lang\":\"markdown\"},\"pin\":\"c765b73b370f0fcaaa3cee28b2be69652e2d2c39\"},\"markdown-toc\":{\"modules\":{\"lang\":\"markdown\"},\"pin\":\"3d724e518a897343b5ede0b976d6fb46c46bcc01\"},\"edit-indirect\":{\"modules\":{\"lang\":\"markdown\"},\"pin\":\"f80f63822ffae78de38dbe72cacaeb1aaa96c732\"},\"evil-markdown\":{\"modules\":{\"lang\":\"markdown\"},\"recipe\":{\"host\":\"github\",\"repo\":\"Somelauw/evil-markdown\"},\"pin\":\"8e6cc68af83914b2fa9fd3a3b8472573dbcef477\"},\"org\":{\"modules\":{\"lang\":\"org\"},\"recipe\":{\"host\":\"github\",\"repo\":\"emacs-straight/org-mode\",\"files\":{\"defaults\":\"etc\"},\"depth\":1,\"build\":true,\"pre-build\":[\"progn\",[\"with-temp-file\",\"org-loaddefs.el\"],[\"with-temp-file\",\"org-version.el\",[\"let\",{\"version\":{\"with-temp-buffer\":{\"insert-file-contents\":[[\"doom-path\",\"lisp/org.el\"],null,0,1024],\"if\":[[\"re-search-forward\",\"^;; Version: \\\\([^\\n-]+\\\\)\",null,true],[\"match-string-no-properties\",1],\"Unknown\"]}}},[\"insert\",[\"format\",\"(defun org-release () %S)\\n\",\"version\"],[\"format\",\"(defun org-git-version (&rest _) \\\"%s-??-%s\\\")\\n\",\"version\",[\"cdr\",[\"doom-call-process\",\"git\",\"rev-parse\",\"--short\",\"HEAD\"]]],\"(provide 'org-version)\\n\"]]]],\"local-repo\":\"org\"},\"pin\":\"e90a8a69a7fa2d83c995b5d32bc0b24a68218ed3\"},\"org-contrib\":{\"modules\":{\"lang\":\"org\"},\"recipe\":{\"host\":\"github\",\"repo\":\"emacsmirror/org-contrib\",\"files\":{\"defaults\":\"lisp/*.el\"}},\"pin\":\"dc59cdd46be8f6854c5d6e9252263d0e4e62e896\"},\"avy\":{\"modules\":{\"lang\":\"org\",\"config\":\"default\"},\"pin\":\"be612110cb116a38b8603df367942e2bb3d9bdbe\"},\"htmlize\":{\"modules\":{\"lang\":\"org\"},\"pin\":\"dd27bc3f26efd728f2b1f01f9e4ac4f61f2ffbf9\"},\"org-yt\":{\"modules\":{\"lang\":\"org\"},\"recipe\":{\"host\":\"github\",\"repo\":\"TobiasZawada/org-yt\"},\"pin\":\"56166f48e04d83668f70ed84706b7a4d8b1e5438\"},\"ox-clip\":{\"modules\":{\"lang\":\"org\"},\"pin\":\"ff117cf3c619eef12eccc0ccbfa3f11adb73ea68\"},\"toc-org\":{\"modules\":{\"lang\":\"org\"},\"pin\":\"6d3ae0fc47ce79b1ea06cabe21a3c596395409cd\"},\"org-cliplink\":{\"modules\":{\"lang\":\"org\"},\"pin\":\"13e0940b65d22bec34e2de4bc8cba1412a7abfbc\"},\"evil-org\":{\"modules\":{\"lang\":\"org\"},\"recipe\":{\"host\":\"github\",\"repo\":\"hlissner/evil-org-mode\",\"flavor\":\"melpa\"},\"pin\":\"a9706da260c45b98601bcd72b1d2c0a24a017700\"},\"orgit\":{\"modules\":{\"lang\":\"org\"},\"pin\":\"4a585029875a1dbbe96d8ac157bd2fd02875f289\"},\"ob-async\":{\"modules\":{\"lang\":\"org\"},\"pin\":\"9aac486073f5c356ada20e716571be33a350a982\"},\"company-shell\":{\"modules\":{\"lang\":\"sh\"},\"pin\":\"5f959a63a6e66eb0cbdac3168cad523a62cc2ccd\"},\"drag-stuff\":{\"modules\":{\"config\":\"default\"},\"pin\":\"6d06d846cd37c052d79acd0f372c13006aa7e7c8\"},\"link-hint\":{\"modules\":{\"config\":\"default\"},\"pin\":\"36ce929331f2838213bcaa1145ece4b73ce84afe\"}}"
        #
        # Currently straight-normalize-all is used to get both variables/the func to populate,
        # but this will need to be changed as it does a lot more net I/O and git ops than is needed.
        #
        # THIS IS WRONG:: ~~The expr (straight--map-existing-repos-interactively (lambda (t) nil))
        # seems to populate all variables, too. So the normalization part of the codepath
        # isn't relevant.~~
        #
        # maybe it's just an autoload somethingsomething hook something??
        # straight-use-package-no-build?? maybe? straight-use-package is the only indirect path to puthash recipe cache
        #
        # OKAY. I got it, it's doom-initalize-packages that does(populates) everything needed. I think it might not
        # even do anything extra that we don't want.
        # its used in doom sync cli -> (doom-packages-install) -> func body starts w call (doom-initialize-packages)
        # oh also btw
        #   ckie@cookiemonster ~/git/nix-doom-emacs -> nix-instantiate --show-trace --json --eval --strict --expr 'with import <nixpkgs> {}; (callPackage ./. { doomPrivateDir = ./test/doom.d ;}).passthru.straightRecipes' | jq .
        # (it's also in the appropiate place in ./default.nix)
        # and 
        #   [nix-shell:~/git/doomemacs]$ emacs --init-directory .
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
