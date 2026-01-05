load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

ISTIO_ORG = "istio"

# 1. Determine SHA256 `wget https://github.com/istio/proxy/archive/$COMMIT.tar.gz && sha256sum $COMMIT.tar.gz`
# 2. Update .bazelversion, envoy.bazelrc and .bazelrc if needed.
#
# Commit date: 2024-08-12
ISTIO_PROXY_SHA = "e80fb95f44230b7843849f2894289eca1652fb59"

ISTIO_PROXY_SHA256 = "18490296e57614644f2e41161bb2375da38810c975e104a16a7995ad99deee04"

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
