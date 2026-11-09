#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ $# == 2 ]] || fail 'usage: update-versions.sh <cachyos|dw> <candidate-output>'
provider=$1
output=$2
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
case "$provider" in
  cachyos)
    pin=$root/proton-cachyos/versions.json
    api=https://api.github.com/repos/CachyOS/proton-cachyos/releases/latest
    tag_pattern='cachyos-([0-9]+\.[0-9]+)-([0-9]{8})-slr'
    ;;
  dw)
    pin=$root/dw-proton/versions.json
    api=https://dawn.wine/api/v1/repos/dawn-winery/dwproton/releases/latest
    tag_pattern='dwproton-([0-9]+\.[0-9]+)-([0-9]+)'
    ;;
  *) fail "unknown provider: $provider" ;;
esac
for accepted in "$root/proton-cachyos/versions.json" "$root/dw-proton/versions.json"; do
  [[ $(realpath -m -- "$output") != "$(realpath -m -- "$accepted")" ]] || fail 'candidate output must not replace an accepted pin'
done
[[ ! -d $output ]] || fail 'candidate output must be a file, not a directory'
[[ -d $(dirname -- "$output") ]] || fail 'candidate output directory does not exist'
work=$(mktemp -d)
output_tmp=
trap 'rm -rf -- "$work"; if [[ -n $output_tmp ]]; then rm -f -- "$output_tmp"; fi' EXIT

fetch() {
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 30 --max-time 900 "$1" --output "$2"
}

asset() {
  local name=$1 expected=$2 url
  url=$(jq -er --arg name "$name" --arg expected "$expected" '
    [.assets[] | select(.name == $name)] |
    if length == 1 and (.[0].browser_download_url | type == "string")
    then
      if .[0].browser_download_url == $expected then .[0].browser_download_url
      else error("asset URL differs from recipe URL: " + $name) end
    else error("missing or duplicate exact asset: " + $name) end
  ' "$work/release.json") || fail "invalid asset: $name"
  printf '%s\n' "$url"
}

fetch "$api" "$work/release.json"
jq -e 'type == "object" and .draft == false and .prerelease == false and
  (.tag_name | type == "string") and (.assets | type == "array") and
  all(.assets[]; type == "object" and (.name | type == "string") and (.browser_download_url | type == "string"))' "$work/release.json" >/dev/null || fail 'invalid stable release object'
jq -e --arg pattern "$tag_pattern" '.tag_name | test("\\A" + $pattern + "\\z")' "$work/release.json" >/dev/null || fail "unsupported $provider tag"
tag=$(jq -r .tag_name "$work/release.json")
[[ $tag =~ ^$tag_pattern$ ]] || fail "unsupported $provider tag: $tag"
base=${BASH_REMATCH[1]}
release=${BASH_REMATCH[2]}
case "$provider" in
  cachyos)
    prefix=https://github.com/CachyOS/proton-cachyos/releases/download/$tag
    declare -A hashes
    for arch in x86_64 x86_64_v3; do
      archive=proton-cachyos-$base-$release-slr-$arch
      asset "$archive.tar.xz" "$prefix/$archive.tar.xz" >/dev/null
      url=$(asset "$archive.sha512sum" "$prefix/$archive.sha512sum")
      fetch "$url" "$work/checksum"
      mapfile -t lines <"$work/checksum"
      [[ ${#lines[@]} == 1 ]] || fail "expected one checksum line: $archive"
      [[ ${lines[0]} =~ ^([0-9a-fA-F]{128})[[:blank:]]([\ \*])(.+)$ ]] || fail "invalid SHA-512 checksum: $archive"
      digest=${BASH_REMATCH[1]}
      [[ ${BASH_REMATCH[3]} == "$archive.tar.xz" ]] || fail "checksum filename mismatch: $archive"
      hashes[$arch]=$(nix hash convert --hash-algo sha512 --to sri "$digest")
    done
    jq -n --arg base "$base" --arg release "$release" --arg baseline "${hashes[x86_64]}" --arg v3 "${hashes[x86_64_v3]}" \
      '{base: $base, release: $release, hashes: {x86_64: $baseline, x86_64_v3: $v3}}' >"$work/candidate.json"
    schema='keys == ["base", "hashes", "release"] and (.base | type == "string" and test("^[0-9]+\\.[0-9]+$")) and
      (.release | type == "string" and test("^[0-9]{8}$")) and (.hashes | type == "object" and keys == ["x86_64", "x86_64_v3"] and
      all(.[]; type == "string" and test("^sha512-[A-Za-z0-9+/]{86}==$")))'
    ;;
  dw)
    archive=dwproton-$base-$release-x86_64.tar.xz
    url=$(asset "$archive" "https://dawn.wine/dawn-winery/dwproton/releases/download/$tag/$archive")
    fetch "$url" "$work/archive.tar.xz"
    hash=$(nix hash file --type sha256 --sri "$work/archive.tar.xz")
    jq -n --arg base "$base" --arg release "$release" --arg hash "$hash" \
      '{base: $base, release: $release, hash: $hash}' >"$work/candidate.json"
    schema='keys == ["base", "hash", "release"] and (.base | type == "string" and test("^[0-9]+\\.[0-9]+$")) and
      (.release | type == "string" and test("^[0-9]+$")) and (.hash | type == "string" and test("^sha256-[A-Za-z0-9+/]{43}=$"))'
    ;;
esac
jq -e "$schema" "$pin" >/dev/null || fail 'invalid accepted pin schema'
jq -e "$schema" "$work/candidate.json" >/dev/null || fail 'invalid candidate schema'
if [[ $(jq -Sc . "$pin") == "$(jq -Sc . "$work/candidate.json")" ]]; then
  printf '%s: no change\n' "$provider"
elif [[ $(jq -r '[.base, .release] | join("-")' "$pin") == "$base-$release" ]]; then
  fail "same tag has a changed digest: $tag; investigate upstream"
else
  printf '%s: candidate %s\n' "$provider" "$tag"
fi
output_tmp=$(mktemp "$(dirname -- "$output")/.version-candidate.XXXXXX")
cp -- "$work/candidate.json" "$output_tmp"
mv -- "$output_tmp" "$output"
output_tmp=
