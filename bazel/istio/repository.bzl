load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

ISTIO_ORG = "istio"

# 1. Determine SHA256 `wget https://github.com/istio/proxy/archive/$COMMIT.tar.gz && sha256sum $COMMIT.tar.gz`
# 2. Update .bazelversion, envoy.bazelrc and .bazelrc if needed.
#
# Commit date: 2025-12-27
ISTIO_PROXY_SHA = "fcbe46286eaaad4242a0384ba109df744a862e7d"

ISTIO_PROXY_SHA256 = "b09725135d490fc46c970677cd4ae22df7071b738ae140a2a1c0d7f87960fe1b"

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
