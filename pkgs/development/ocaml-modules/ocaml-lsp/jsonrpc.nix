{ buildDunePackage
, stdlib-shims
, ppx_yojson_conv_lib
, ocaml-syntax-shims
, yojson
, result
, fetchurl
, lib
, ocaml
}:

let params =
  if lib.versionAtLeast ocaml.version "4.14"
  then {
    version = "1.11.3";
    sha256 = "sha256-KlMFh05O04I0Xil2B+nL2hUxZw0jaDMUnI23oUwGyhs=";
  } else if lib.versionAtLeast ocaml.version "4.13"
  then {
    version = "1.10.5";
    sha256 = "sha256-TeJS6t1ruWhWPvWNatrnSUWI6T17XKiosHLYizBDDcw=";
  } else if lib.versionAtLeast ocaml.version "4.12"
  then {
    version = "1.9.0";
    sha256 = "sha256:1ac44n6g3rf84gvhcca545avgf9vpkwkkkm0s8ipshfhp4g4jikh";
  } else {
    version = "1.4.1";
    sha256 = "1ssyazc0yrdng98cypwa9m3nzfisdzpp7hqnx684rqj8f0g3gs6f";
  }
; in

buildDunePackage rec {
  pname = "jsonrpc";
  inherit (params) version;
  src = fetchurl {
    url = "https://github.com/ocaml/ocaml-lsp/releases/download/${version}/jsonrpc-${version}.tbz";
    inherit (params) sha256;
  };

  duneVersion = if lib.versionAtLeast version "1.10.0" then "3" else "2";
  minimalOCamlVersion = "4.06";

  buildInputs =
    if lib.versionAtLeast version "1.7.0" then
      [ ]
    else
      [ yojson stdlib-shims ocaml-syntax-shims ];

  propagatedBuildInputs =
    if lib.versionAtLeast version "1.7.0" then
      [ ]
    else
      [ ppx_yojson_conv_lib result ];

  meta = with lib; {
    description = "Jsonrpc protocol implementation in OCaml";
    license = licenses.isc;
    platforms = platforms.unix;
    maintainers = with maintainers; [ symphorien marsam ];
  };
}
