{ lib
, stdenv
, fetchurl
, dwProtonVersions
}:

stdenv.mkDerivation rec {
  pname = "dw-proton";
  version = "${dwProtonVersions.base}-${dwProtonVersions.release}";

  archiveName = "dwproton-${version}-x86_64";
  protonDisplayName = "DW-Proton-${version}";

  src = fetchurl {
    url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/${archiveName}.tar.xz";
    inherit (dwProtonVersions) hash;
  };

  postPatch = ''
    substituteInPlace "compatibilitytool.vdf" \
      --replace-fail "${archiveName}" "${protonDisplayName}"
    
    rm -f files/share/default_pfx*/.update-timestamp

    substituteInPlace proton \
      --replace-fail \
        "with open(os.path.join(self.prefix_dir, '.update-timestamp'), 'w') as update_timestamp:" \
        "with open(os.devnull, 'w') as update_timestamp:"
  '';

  installPhase = ''
    mkdir -p $out/share/steam/compatibilitytools.d/dw-proton
    mv * $out/share/steam/compatibilitytools.d/dw-proton/
  '';

  meta = with lib; {
    description = "Dawn Winery Proton build";
    homepage = "https://dawn.wine/dawn-winery/dwproton";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ shochraos ];
  };
}