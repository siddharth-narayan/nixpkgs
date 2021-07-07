{ lib
, stdenv
, fetchFromGitHub
, cups
, cups-filters
, ghostscript
, gnused
, perl
, autoconf
, automake
, patchPpdFilesHook
}:

stdenv.mkDerivation {
  pname = "foomatic-db";
  version = "unstable-2022-10-03";

  src = fetchFromGitHub {
    # there is also a daily snapshot at the `downloadPage`,
    # but it gets deleted quickly and would provoke 404 errors
    owner = "OpenPrinting";
    repo = "foomatic-db";
    rev = "2a3c4d1bf7eadc42f936ce8989c1dd2973ea9669";
    hash = "sha256-in0/j1nAQvM0NowBIBx3jj5WVMPIfZAeAk1SkuA3tjA=";
  };

  buildInputs = [ cups cups-filters ghostscript gnused perl ];

  nativeBuildInputs = [ autoconf automake patchPpdFilesHook perl ];

  # sed-substitute indirection is more robust
  # against characters in paths that might need escaping
  postPatch = ''
    sed -Ei -e 's|^(S?BINSEARCHPATH=).+$|\1"@PATH@"|g'  \
      -e 's|^(DATASEARCHPATH=).+$|\1"@DATA@"|g' configure.ac
    substituteInPlace configure.ac  \
      --subst-var PATH  \
      --subst-var-by DATA "${placeholder "out"}/share"
  '';

  preConfigure = ''
    mkdir -p "${placeholder "out"}/share/foomatic/db/source"
    ./make_configure
  '';

  # don't let the intaller gzip ppd files as we would
  # have to unzip them later in order to patch them
  configureFlags = [ "--disable-gzip-ppds" ];

  # make ppd files available to cups,
  # use a package-specific subdirectory to avoid
  # conflicts with other ppd-containing packages
  postInstall = ''
    if ! [[ -d "${placeholder "out"}/share/foomatic/db/source/PPD" ]]; then
        echo "failed to create share/foomatic/db/source/PPD"
        exit 1
    fi
    mkdir -p "${placeholder "out"}/share/cups/model"
    ln -s "${placeholder "out"}/share/foomatic/db/source/PPD"  \
      "${placeholder "out"}/share/cups/model/foomatic-db"
  '';

  # Comments indicate the respective
  # package the command is contained in.
  ppdFileCommands = [
    "cat" "date" "printf"  # coreutils
    "rastertohp"  # cups
    "foomatic-rip"  # cups-filters or foomatic-filters
    "gs"  # ghostscript
    "sed"  # gnused
    "perl"  # perl
  ];

  # compress ppd files
  postFixup = ''
    echo 'compressing ppd files'
    find -H "${placeholder "out"}/share/cups/model/foomatic-db" -type f -iname '*.ppd' -print0  \
      | xargs -0r -n 64 -P "$NIX_BUILD_CORES" gzip -9n
  '';

  meta = {
    description = "OpenPrinting printer support database (free content)";
    downloadPage = "https://www.openprinting.org/download/foomatic/";
    homepage = "https://openprinting.github.io/projects/02-foomatic/";
    license = lib.licenses.free;  # mostly GPL and MIT, see README in source dir
    maintainers = [ lib.maintainers.yarny ];
    # list printer manufacturers here so people
    # searching for ppd files can find this package
    longDescription = ''
      The collected knowledge about printers,
      drivers, and driver options in XML files.
      Besides the XML files, this package contains
      about 6,600 PPD files, for printers from
      Brother, Canon, Epson, Gestetner, HP, InfoPrint,
      Infotec, KONICA_MINOLTA, Kyocera, Lanier, Lexmark, NRG,
      Oce, Oki, Ricoh, Samsung, Savin, Sharp, Toshiba and Utax.
    '';
  };
}
