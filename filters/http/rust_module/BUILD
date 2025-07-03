load("@rules_rust//rust:defs.bzl", "rust_shared_library", "rust_test")

rust_shared_library(
    name = "rust_module",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    rustc_flags = [
        "-C",
        "link-args=-Wl,-undefined,dynamic_lookup",
    ],
    deps = [
        "@envoy//source/extensions/dynamic_modules/sdk/rust:envoy_proxy_dynamic_modules_rust_sdk",
        "@crate_index//:regex",
    ],
    visibility = ["//:__pkg__"],
)

rust_test(
    name = "unit_test",
    crate = ":rust_module",
    deps = [],
)
