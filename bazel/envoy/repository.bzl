load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# 1. Determine SHA256 `wget https://github.com/envoyproxy/envoy/archive/$COMMIT.tar.gz && sha256sum $COMMIT.tar.gz`
# 2. Update .bazelversion, envoy.bazelrc and .bazelrc if needed.
#
# Commit date: 2025-12-10
ENVOY_SHA = "44d1844d2480c42e4c2cb6e8a7872d57367604eb"

ENVOY_SHA256 = "54dc9e8a224fb789f1759848cb8e003f3257c1a31aa104ca2b0d1372001cde2a"

ENVOY_ORG = "envoyproxy"

ENVOY_REPO = "envoy"

def envoy_repository():
    # To override with local envoy, just pass `--override_repository=envoy=/PATH/TO/ENVOY` to Bazel or
    # persist the option in `user.bazelrc`.
    http_archive(
        name = "envoy",
        sha256 = ENVOY_SHA256,
        strip_prefix = ENVOY_REPO + "-" + ENVOY_SHA,
        url = "https://github.com/" + ENVOY_ORG + "/" + ENVOY_REPO + "/archive/" + ENVOY_SHA + ".tar.gz",
    )
