load("@envoy//bazel:envoy_build_system.bzl", "envoy_cc_binary")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

exports_files(["LICENSE"])

config_setting(
    name = "darwin",
    values = {
        "cpu": "darwin",
    },
)

ISTIO_EXTENSIONS = [
    "@istio//source/extensions/common/workload_discovery:api_lib",  # Experimental: WIP
    "@istio//source/extensions/filters/http/alpn:config_lib",
    "@istio//source/extensions/filters/http/istio_stats",
    "@istio//source/extensions/filters/http/peer_metadata:filter_lib",
    "@istio//source/extensions/filters/network/metadata_exchange:config_lib",
]

envoy_cc_binary(
    name = "envoy",
    repository = "@envoy",
    deps = ISTIO_EXTENSIONS + [
        "@envoy//source/exe:envoy_main_entry_lib",
    ],
)

pkg_tar(
    name = "envoy_tar",
    srcs = [":envoy"],
    extension = "tar.gz",
    mode = "0755",
    package_dir = "/usr/local/bin/",
    tags = ["manual"],
)
