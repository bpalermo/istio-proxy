load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# 1. Determine SHA256 `wget https://github.com/envoyproxy/envoy/archive/$COMMIT.tar.gz && sha256sum $COMMIT.tar.gz`
# 2. Update .bazelversion, envoy.bazelrc and .bazelrc if needed.
#
# Commit date: 2025-05-29
#ENVOY_SHA = "e31a656721f04ac68255db3befc15560ffa19f85"
ENVOY_SHA = "44b00e0264cfcdbbc593998a407b3f957ec28c77"

#ENVOY_SHA256 = "e53f1c083fda2114ec132360b7c78c4e385f1328ffb61b3eb690487c58d5929c"
ENVOY_SHA256 = "1c8bc33cf9b758604042212d69d8bc37f41991facc43ed139d070b6b94aeddb0"

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
        #        patches = [
        #            "//bazel/envoy:quic-mtls.patch",
        #        ],
        #        patch_args = ["-p1"],  # Strip one directory level from patch paths
    )
