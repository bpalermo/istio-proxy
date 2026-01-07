load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# 1. Determine SHA256 `wget https://github.com/envoyproxy/envoy/archive/$COMMIT.tar.gz && sha256sum $COMMIT.tar.gz`
# 2. Update .bazelversion, envoy.bazelrc and .bazelrc if needed.
#
# Commit date: 2025-12-10
ENVOY_SHA = "809213ab4403f02b04521567715f97ad5a1ae597"

ENVOY_SHA256 = "a7f121ecd10b8ced4abddb3004306e44fd273b4d893363d2713bdce03c1b5a95"

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
        patches = [
            "@github_com_bpalermo_istio_proxy//bazel/envoy:quic.patch",
        ],
        patch_args = ["-p1"],  # Strip one directory level from patch paths
    )
