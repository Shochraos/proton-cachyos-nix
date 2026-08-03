{
  lib,
  stdenvNoCC,
  fetchurl,
  protonCachyosVersions,
  microArchitecture ? "x86_64",
}:

let
  inherit (protonCachyosVersions) base release hashes;

  version = "${base}-${release}";
  tag = "cachyos-${version}-slr";
  archive = "proton-cachyos-${version}-slr-${microArchitecture}";

  toolName = "proton-cachyos-slr";
  displayName = "Proton-CachyOS-${version}-${microArchitecture}";
in

assert lib.assertMsg (builtins.hasAttr microArchitecture hashes)
  "proton-cachyos: no hash recorded for microArchitecture '${microArchitecture}', known: ${lib.concatStringsSep ", " (builtins.attrNames hashes)}";

stdenvNoCC.mkDerivation {
  pname = "proton-cachyos-slr-${microArchitecture}";
  inherit version;

  src = fetchurl {
    url = "https://github.com/CachyOS/proton-cachyos/releases/download/${tag}/${archive}.tar.xz";
    hash = hashes.${microArchitecture};
  };

  sourceRoot = ".";

  postPatch = ''
    substituteInPlace ${archive}/compatibilitytool.vdf \
      --replace-fail '"display_name" "${archive}"' '"display_name" "${displayName}"' \
      --replace-fail '"${archive}"' '"${toolName}"'

    rm -f ${archive}/files/share/default_pfx*/.update-timestamp

    substituteInPlace ${archive}/proton \
      --replace-fail \
        "with open(os.path.join(self.prefix_dir, '.update-timestamp'), 'w') as update_timestamp:" \
        "with open(os.devnull, 'w') as update_timestamp:"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/steam/compatibilitytools.d
    mv ${archive} $out/share/steam/compatibilitytools.d/${toolName}

    runHook postInstall
  '';

  meta = with lib; {
    description = "CachyOS Proton build with additional patches and optimizations";
    homepage = "https://github.com/CachyOS/proton-cachyos";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ shochraos ];
  };
}
