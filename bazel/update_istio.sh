#!/usr/bin/env bash
#
# Moves the build to an istio/istio commit, and to the istio/proxy and Envoy
# commits that commit was built against:
#
#   istio/istio  -> go.mod (pilot-agent, bootstrap template), ISTIO_SHA
#   istio/proxy  -> ISTIO_PROXY_SHA, bazel/extension_config/istio_extensions_build_config.bzl
#   envoy        -> MODULE.bazel and the rest, through bazel/update_envoy.sh
#
#   bazel/update_istio.sh              # latest commit of istio/istio master
#   ISTIO_SHA=<commit> bazel/update_istio.sh
#
# The base image is not moved: when BASE_VERSION in istio/istio's
# Makefile.core.mk changes, the script says so and the digest in MODULE.bazel
# has to be updated by hand.

set -euo pipefail

UPDATE_BRANCH=${UPDATE_BRANCH:-master}
ISTIO_SHA=${ISTIO_SHA:-}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT}"
VERSIONS=bazel/versions.bzl

if [[ -z "${ISTIO_SHA}" ]]; then
  ISTIO_SHA="$(git ls-remote https://github.com/istio/istio "refs/heads/${UPDATE_BRANCH}" | awk '{print $1}')"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

ISTIO_RAW="https://raw.githubusercontent.com/istio/istio/${ISTIO_SHA}"
curl -sSfL "${ISTIO_RAW}/istio.deps" -o "${WORK}/istio.deps"
curl -sSfL "${ISTIO_RAW}/Makefile.core.mk" -o "${WORK}/Makefile.core.mk"
curl -sSfL "${ISTIO_RAW}/pilot/cmd/pilot-agent/main.go" -o "${WORK}/main.go"

PROXY_SHA="$(jq -r '.[] | select(.name == "PROXY_REPO_SHA") | .lastStableSHA' "${WORK}/istio.deps")"
if ! grep -Eq '^[0-9a-f]{40}$' <<<"${PROXY_SHA}"; then
  echo "could not read PROXY_REPO_SHA from istio.deps" >&2
  exit 1
fi

PROXY_RAW="https://raw.githubusercontent.com/istio/proxy/${PROXY_SHA}"
curl -sSfL "${PROXY_RAW}/MODULE.bazel" -o "${WORK}/proxy.MODULE.bazel"
curl -sSfL "${PROXY_RAW}/bazel/extension_config/extensions_build_config.bzl" -o "${WORK}/extensions_build_config.bzl"
ENVOY_SHA="$(grep -Pom1 '^ENVOY_SHA = "\K[0-9a-f]+' "${WORK}/proxy.MODULE.bazel")"

OLD_PROXY_SHA="$(grep -Pom1 '^ISTIO_PROXY_SHA = "\K[0-9a-f]+' "${VERSIONS}")"

# pilot-agent: the module, and the copy of its main package. The go command is
# the SDK Bazel downloads, not one from the host.
bazel run @rules_go//go -- get "istio.io/istio@${ISTIO_SHA}"
cp "${WORK}/main.go" cmd/pilot-agent/main.go
bazel run @rules_go//go -- mod tidy

sed -i "s/^ISTIO_SHA = .*/ISTIO_SHA = \"${ISTIO_SHA}\"/" "${VERSIONS}"
sed -i "s/^ISTIO_PROXY_SHA = .*/ISTIO_PROXY_SHA = \"${PROXY_SHA}\"/" "${VERSIONS}"
sed -i "s/${OLD_PROXY_SHA}/${PROXY_SHA}/" testdata/image.yaml

cp "${WORK}/extensions_build_config.bzl" bazel/extension_config/istio_extensions_build_config.bzl

ENVOY_SHA="${ENVOY_SHA}" bazel/update_envoy.sh

BASE_VERSION="$(grep -Pom1 '^BASE_VERSION \?= \K\S+' "${WORK}/Makefile.core.mk")"
if ! grep -q "iptables:${BASE_VERSION}" MODULE.bazel; then
  echo "NOTE: istio/istio now builds on base ${BASE_VERSION}; update the istio_iptables digest and its comment in MODULE.bazel" >&2
fi

echo "Istio is now ${ISTIO_SHA}, istio/proxy ${PROXY_SHA}, Envoy ${ENVOY_SHA}"
