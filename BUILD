load("@envoy//bazel:envoy_build_system.bzl", "envoy_cc_binary")
load("@rules_go//go:def.bzl", "TOOLS_NOGO", "nogo")
load("@rules_img//img:image.bzl", "image_index", "image_manifest")
load("@rules_img//img:layer.bzl", "file_metadata", "image_layer")
load("@rules_img//img:load.bzl", "image_load")
load("@rules_img//img:push.bzl", "image_push")
load("@rules_img//img:test.bzl", "image_structure_test")
load("//bazel:versions.bzl", "ISTIO_PROXY_SHA")

exports_files([
    ".shellcheckrc",
    "LICENSE",
])

# The analyzers this module's Go packages are compiled with (go_sdk.nogo in
# MODULE.bazel): the ones `go vet` runs and the rest of the x/tools set that
# rules_go recommends. A finding fails the build.
nogo(
    name = "nogo",
    visibility = ["//visibility:public"],
    deps = TOOLS_NOGO,
)

alias(
    name = "format",
    actual = "//bazel/format",
)

alias(
    name = "format.check",
    actual = "//bazel/format:format.check",
)

# envoy, the layers and the manifest are tagged "manual" to keep them out of
# //...: :image builds them once per architecture, and building them for the
# host configuration as well would only repeat the amd64 Envoy build.
#
# The Istio filters live in Envoy's contrib/istio and are enabled, with the
# rest of the extension set, in //bazel/extension_config.
envoy_cc_binary(
    name = "envoy",
    tags = ["manual"],
    deps = ["@envoy//source/exe:envoy_main_entry_lib"],
)

# The image has what istio/istio's pilot/docker/Dockerfile.proxyv2 puts in the
# distroless proxyv2 image, at the same paths.
image_layer(
    name = "envoy_layer",
    srcs = {"/usr/local/bin/envoy": ":envoy"},
    compress = "zstd",
    default_metadata = file_metadata(
        gid = 0,
        mode = "0755",
        uid = 0,
    ),
    include_runfiles = False,
    tags = ["manual"],
)

image_layer(
    name = "pilot_agent_layer",
    srcs = {
        "/usr/local/bin/pilot-agent": "//cmd/pilot-agent",
        "/var/lib/istio/envoy/envoy_bootstrap_tmpl.json": "@io_istio_istio//tools/packaging/common:envoy_bootstrap.json",
    },
    compress = "zstd",
    default_metadata = file_metadata(
        gid = 0,
        mode = "0755",
        uid = 0,
    ),
    file_metadata = {
        "/var/lib/istio/envoy/envoy_bootstrap_tmpl.json": file_metadata(mode = "0644"),
    },
    include_runfiles = False,
    tags = ["manual"],
)

image_manifest(
    name = "image_manifest",
    base = "@istio_iptables",
    entrypoint = ["/usr/local/bin/pilot-agent"],
    env = {"ISTIO_META_ISTIO_PROXY_SHA": ISTIO_PROXY_SHA},
    layers = [
        ":envoy_layer",
        ":pilot_agent_layer",
    ],
    tags = ["manual"],
    working_dir = "/",
)

# One manifest per platform: the index builds envoy and pilot-agent for each.
image_index(
    name = "image",
    manifests = [":image_manifest"],
    platforms = [
        "//bazel/platforms:linux_amd64",
        "//bazel/platforms:linux_arm64",
    ],
)

image_load(
    name = "load",
    image = ":image",
    tag = "palermo/istio-proxy:latest",
)

image_push(
    name = "push",
    image = ":image",
    registry = "index.docker.io",
    repository = "palermo/istio-proxy",
    # Stamp the tag without --stamp, which would stamp, and so rebuild, Envoy
    # too. Only the tag expansion reads the workspace status.
    stamp = "force",
    tag_list = ["{{.STABLE_GIT_COMMIT}}"],
)

image_structure_test(
    name = "image_test",
    configs = ["testdata/image.yaml"],
    image = ":image",
)
