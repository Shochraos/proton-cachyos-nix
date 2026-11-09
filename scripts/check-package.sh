#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ $# == 2 ]] || fail 'usage: check-package.sh <package-attribute> <realized-output>'
attribute=$1
output=$2
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
case "$attribute" in
  proton-cachyos | proton-cachyos-v3)
    pin=$root/proton-cachyos/versions.json
    version=$(jq -er 'select((.base | type) == "string" and (.release | type) == "string") | .base + "-" + .release' "$pin")
    [[ $version =~ ^[0-9]+\.[0-9]+-[0-9]{8}$ ]] || fail 'invalid CachyOS version'
    arch=x86_64
    [[ $attribute != proton-cachyos-v3 ]] || arch=x86_64_v3
    directory=proton-cachyos-slr
    identity=proton-cachyos-slr
    display=Proton-CachyOS-$version-$arch
    ;;
  dw-proton)
    pin=$root/dw-proton/versions.json
    version=$(jq -er 'select((.base | type) == "string" and (.release | type) == "string") | .base + "-" + .release' "$pin")
    [[ $version =~ ^[0-9]+\.[0-9]+-[0-9]+$ ]] || fail 'invalid DW version'
    directory=dw-proton
    identity=DW-Proton-$version
    display=$identity
    ;;
  *) fail "unknown package attribute: $attribute" ;;
esac
tool=$output/share/steam/compatibilitytools.d/$directory
[[ -f $tool/compatibilitytool.vdf ]] || fail 'missing compatibilitytool.vdf'
[[ -f $tool/proton && -x $tool/proton ]] || fail 'missing executable proton'
awk -v identity="$identity" -v display="$display" '
  function reject() { bad = 1; exit 1 }
  function token(kind, value) {
    if (++tokens > 4096) reject()
    if (kind == "string") {
      if (!pending) { key = value; pending = 1; return }
      if (depth != 3) reject()
      if (key == "display_name") {
        displays++
        if (value != display) reject()
      }
      pending = 0
    } else if (kind == "{") {
      if (!pending) reject()
      if (depth == 0 && key == "compatibilitytools") roots++
      else if (depth == 1 && key == "compat_tools") mappings++
      else if (depth == 2 && key == identity) identities++
      else reject()
      depth++
      pending = 0
    } else {
      if (pending || depth == 0) reject()
      depth--
    }
  }
  {
    bytes += length($0) + 1
    if (bytes > 65536) reject()
    line = $0
    while (length(line)) {
      if (match(line, /^[[:space:]]+/)) line = substr(line, RLENGTH + 1)
      else if (substr(line, 1, 2) == "//") break
      else if (match(line, /^"([^"\\]|\\.)*"/)) {
        value = substr(line, 2, RLENGTH - 2)
        line = substr(line, RLENGTH + 1)
        token("string", value)
      } else if (substr(line, 1, 1) == "{" || substr(line, 1, 1) == "}") {
        token(substr(line, 1, 1), "")
        line = substr(line, 2)
      } else reject()
    }
  }
  END { exit !(!bad && !pending && depth == 0 && roots == 1 && mappings == 1 && identities == 1 && displays == 1) }
' "$tool/compatibilitytool.vdf" || fail 'VDF identity or display name mismatch'
ancestor=$tool/files/share
while [[ $ancestor != / && $ancestor != . ]]; do
  [[ ! -L $ancestor ]] || fail "symlinked default prefix ancestor: $ancestor"
  ancestor=$(dirname -- "$ancestor")
done
shopt -s nullglob
prefixes=("$tool"/files/share/default_pfx*)
[[ -d $tool/files/share/default_pfx && ${#prefixes[@]} -gt 0 ]] || fail 'missing expected default prefix inventory'
for prefix in "${prefixes[@]}"; do
  [[ -d $prefix && ! -L $prefix ]] || fail "default prefix is not a physical directory: $prefix"
done
markers=$(find -P "${prefixes[@]}" -name .update-timestamp -print) || fail 'cannot inspect default prefixes'
[[ -z $markers ]] || fail "shipped timestamp markers remain: $markers"
grep -Fq "with open(os.devnull, 'w') as update_timestamp:" "$tool/proton" || fail 'missing timestamp-write patch'
if grep -Fq "with open(os.path.join(self.prefix_dir, '.update-timestamp'), 'w') as update_timestamp:" "$tool/proton"; then
  fail 'old timestamp-write statement remains'
fi
printf 'Verified %s (%s); inspected %s default prefix directories\n' "$attribute" "$version" "${#prefixes[@]}"
