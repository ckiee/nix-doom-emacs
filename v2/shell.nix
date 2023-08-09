{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    bubblewrap emacs28-gtk3
  ];
  shellHook = ''
    export XDG_CONFIG_HOME="$PWD"
    export DOOMDIR=doom
  '';
}
