{ fetchFromGitHub, trivialBuild }:

trivialBuild rec {
  pname = "straight.el";
  version = "unstable-2023-08-08";
  ename = pname;
  patches = [ ./nogit.patch ];
  src = fetchFromGitHub {
    owner = "raxod502";
    repo = "straight.el";
    rev = "9b11112b2e7aedd994feb2d8f95bd66dbc5749a5";
    sha256 = "sha256-CIUMmykpUMv2sGDdBQjJLRH9+RLF9IkUG1FypM6esA8=";
  };
}
