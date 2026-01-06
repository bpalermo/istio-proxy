load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

ISTIO_ORG = "istio"

# 1. Determine SHA256 `wget https://github.com/istio/proxy/archive/$COMMIT.tar.gz && sha256sum $COMMIT.tar.gz`
# 2. Update .bazelversion, envoy.bazelrc and .bazelrc if needed.
#
# Commit date: 2024-12-11
ISTIO_PROXY_SHA = "0879e0055d1da524a89415acd456e230b27fba70"

ISTIO_PROXY_SHA256 = "e377dcf9b6b203dc9b3a63dff1726f6a1c73653182404cbc47b6a3c4356e17fd"

ISTIO_PROXY_REPO = "proxy"

def istio_repository():
    # To override with local envoy, just pass `--override_repository=envoy=/PATH/TO/ENVOY` to Bazel or
    # persist the option in `user.bazelrc`.
    http_archive(
        name = "istio_proxy",
        sha256 = ISTIO_PROXY_SHA256,
        strip_prefix = ISTIO_PROXY_REPO + "-" + ISTIO_PROXY_SHA,
        url = "https://github.com/" + ISTIO_ORG + "/" + ISTIO_PROXY_REPO + "/archive/" + ISTIO_PROXY_SHA + ".tar.gz",
    )
