#!/usr/bin/env bash
#
# Moves the Envoy pin in MODULE.bazel and everything that has to move with it.
# Adapted from istio/proxy's scripts/update_envoy.sh.
#
#   bazel/update_envoy.sh              # latest commit of envoyproxy/envoy main
#   ENVOY_SHA=<commit> bazel/update_envoy.sh
#
# Normally run by bazel/update_istio.sh, with the commit istio/proxy pins.

set -euo pipefail

UPDATE_BRANCH=${UPDATE_BRANCH:-main}
ENVOY_SHA=${ENVOY_SHA:-}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT}"
MODULE_BAZEL=${ROOT}/MODULE.bazel

ENVOY_ORG="$(grep -Pom1 '^ENVOY_ORG = "\K[a-zA-Z-]+' "${MODULE_BAZEL}")"
ENVOY_REPO="$(grep -Pom1 '^ENVOY_REPO = "\K[a-zA-Z-]+' "${MODULE_BAZEL}")"
RAW="https://raw.githubusercontent.com/${ENVOY_ORG}/${ENVOY_REPO}"

if [[ -z "${ENVOY_SHA}" ]]; then
  ENVOY_SHA="$(git ls-remote "https://github.com/${ENVOY_ORG}/${ENVOY_REPO}" "refs/heads/${UPDATE_BRANCH}" | awk '{print $1}')"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

DATE="$(curl -sSfL -H 'Accept: application/vnd.github.v3+json' \
  "https://api.github.com/repos/${ENVOY_ORG}/${ENVOY_REPO}/commits/${ENVOY_SHA}" |
  jq -r '.commit.committer.date' | cut -dT -f1)"

curl -sSfL "https://github.com/${ENVOY_ORG}/${ENVOY_REPO}/archive/${ENVOY_SHA}.tar.gz" -o "${WORK}/envoy.tar.gz"
SHA256="$(sha256sum "${WORK}/envoy.tar.gz" | awk '{print $1}')"

# -f matters: without it a 404 body would be written into these files.
curl -sSfL "${RAW}/${ENVOY_SHA}/.bazelversion" -o "${WORK}/bazelversion"
curl -sSfL "${RAW}/${ENVOY_SHA}/.bazelrc" -o "${WORK}/envoy.bazelrc"
curl -sSfL "${RAW}/${ENVOY_SHA}/VERSION.txt" -o "${WORK}/VERSION.txt"
curl -sSfL "${RAW}/${ENVOY_SHA}/MODULE.bazel" -o "${WORK}/envoy.MODULE.bazel"
curl -sSfL "${RAW}/${ENVOY_SHA}/api/MODULE.bazel" -o "${WORK}/envoy_api.MODULE.bazel"

ENVOY_VERSION="$(cat "${WORK}/VERSION.txt")"
if ! grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-dev)?$' <<<"${ENVOY_VERSION}"; then
  echo "unexpected Envoy VERSION.txt: ${ENVOY_VERSION}" >&2
  exit 1
fi

cp "${WORK}/bazelversion" .bazelversion
cp "${WORK}/envoy.bazelrc" envoy.bazelrc
cp "${WORK}/VERSION.txt" ENVOY_VERSION.txt

sed -i "s/^# Commit date: .*/# Commit date: ${DATE}/" "${MODULE_BAZEL}"
sed -i "s/^ENVOY_SHA = .*/ENVOY_SHA = \"${ENVOY_SHA}\"/" "${MODULE_BAZEL}"
sed -i "s/^ENVOY_SHA256 = .*/ENVOY_SHA256 = \"${SHA256}\"/" "${MODULE_BAZEL}"

# Every bazel_dep declared here that Envoy (or envoy_api) also declares is
# pinned to Envoy's version; envoy and envoy_api themselves to VERSION.txt.
# rules_img is not Envoy's and is left alone.
sed -nE 's/^bazel_dep\(name = "([^"]+)", version = "([^"]+)".*/\1\t\2/p' \
  "${WORK}/envoy.MODULE.bazel" "${WORK}/envoy_api.MODULE.bazel" >"${WORK}/versions.tsv"

awk -v versions="${WORK}/versions.tsv" -v envoy_version="${ENVOY_VERSION}" '
BEGIN {
  while ((getline line < versions) > 0) {
    split(line, kv, "\t")
    if (!(kv[1] in upstream)) upstream[kv[1]] = kv[2]
  }
  upstream["envoy"] = envoy_version
  upstream["envoy_api"] = envoy_version
}
{
  line = $0
  if (match(line, /^bazel_dep\(name = "[^"]+", version = "[^"]+"/)) {
    name = line
    sub(/^bazel_dep\(name = "/, "", name)
    sub(/".*/, "", name)
    if (name in upstream) {
      sub(/version = "[^"]+"/, "version = \"" upstream[name] "\"", line)
    } else {
      print "note: " name " is not declared by Envoy; version left as is" > "/dev/stderr"
    }
  }
  print line
}' "${MODULE_BAZEL}" >"${WORK}/MODULE.bazel"

if [[ "$(wc -l <"${WORK}/MODULE.bazel")" -ne "$(wc -l <"${MODULE_BAZEL}")" ]]; then
  echo "MODULE.bazel rewrite changed the line count; aborting" >&2
  exit 1
fi
cp "${WORK}/MODULE.bazel" "${MODULE_BAZEL}"

# The lockfile records digests of Envoy's module extensions; CI builds with
# --lockfile_mode=error, so it has to be refreshed with the pin.
bazel mod deps --lockfile_mode=update >/dev/null

echo "Envoy is now ${ENVOY_VERSION} at ${ENVOY_SHA} (${DATE})"
