{
  lib,
  stdenv,
  fetchurl,
  zstd,
  protonCachyosVersions,
}:

stdenv.mkDerivation rec {
  pname = "proton-cachyos-slr";
  version = "${protonCachyosVersions.base}-${protonCachyosVersions.release}";

  archiveName = "proton-cachyos-${version}-slr-x86_64";
  protonDisplayName = "Proton-CachyOS-${version}";

  src = fetchurl {
    url = "https://mirror.cachyos.org/repo/x86_64/cachyos/proton-cachyos-slr-1:${protonCachyosVersions.base}.${protonCachyosVersions.release}-1-x86_64.pkg.tar.zst";
    inherit (protonCachyosVersions) hash;
  };

  nativeBuildInputs = [ zstd ];

  unpackPhase = ''
    tar -I zstd -xf $src
  '';

  postPatch = ''
    substituteInPlace "usr/share/steam/compatibilitytools.d/proton-cachyos-slr/compatibilitytool.vdf" \
      --replace-fail "$archiveName" "${protonDisplayName}"
  '';

  installPhase = ''
    mkdir -p $out/share/steam/compatibilitytools.d
    mv usr/share/steam/compatibilitytools.d/proton-cachyos-slr $out/share/steam/compatibilitytools.d/
  '';

  meta = with lib; {
    description = "CachyOS Proton build with additional patches and optimizations";
    homepage = "https://github.com/CachyOS/proton-cachyos";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ shochraos ];
  };
}
