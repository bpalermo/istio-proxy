load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

ISTIO_ORG = "istio"

# 1. Determine SHA256 `wget https://github.com/istio/proxy/archive/$COMMIT.tar.gz && sha256sum $COMMIT.tar.gz`
# 2. Update .bazelversion, envoy.bazelrc and .bazelrc if needed.
#
# Commit date: 2024-08-12
ISTIO_PROXY_SHA = "19d31b12e62848c5e9f3f786c6c9a650ebc00b64"

ISTIO_PROXY_SHA256 = "729edc510635701fd179eba1b7e724b62efe7bc5db0b89caca3cd59990c8b67f"

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
