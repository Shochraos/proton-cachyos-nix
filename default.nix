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

  archiveName = "proton-cachyos-${version} (steam linux runtime)";
  protonDisplayName = "Proton-CachyOS-${version}";

  src = fetchurl {
    url = "https://mirror.cachyos.org/repo/x86_64/cachyos/proton-cachyos-slr-${protonCachyosVersions.epoch}:${protonCachyosVersions.base}.${protonCachyosVersions.release}-${protonCachyosVersions.pkgrel}-x86_64.pkg.tar.zst";    inherit (protonCachyosVersions) hash;
  };

  nativeBuildInputs = [ zstd ];

  unpackPhase = ''
    tar -I zstd -xf $src
  '';

  postPatch = ''
    toolDir=usr/share/steam/compatibilitytools.d/proton-cachyos-slr

    substituteInPlace "$toolDir/compatibilitytool.vdf" \
      --replace-fail "${archiveName}" "${protonDisplayName}"

    rm -f "$toolDir"/files/share/default_pfx*/.update-timestamp

    substituteInPlace "$toolDir/proton" \
      --replace-fail \
        "with open(os.path.join(self.prefix_dir, '.update-timestamp'), 'w') as update_timestamp:" \
        "with open(os.devnull, 'w') as update_timestamp:"
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
