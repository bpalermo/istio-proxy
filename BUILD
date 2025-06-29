load("@container_structure_test//:defs.bzl", "container_structure_test")
load("@envoy//bazel:envoy_build_system.bzl", "envoy_cc_binary")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load", "oci_push")

# Copyright 2016 Istio Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################
#
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
    owner = "65532.65532",
    package_dir = "/usr/local/bin/",
    tags = ["manual"],
)

pkg_tar(
    name = "rust_module_tar",
    srcs = ["//filters/http/rust_module"],
    extension = "tar.gz",
    mode = "0755",
    owner = "65532.65532",
    package_dir = "/usr/local/lib/",
    visibility = ["//visibility:public"],
)

oci_image(
    name = "image",
    base = "@distroless_cc_debian12_nonroot",
    entrypoint = ["/usr/local/bin/envoy"],
    env = {
        "ENVOY_DYNAMIC_MODULES_SEARCH_PATH": "/usr/local/lib",
    },
    tars = [
        ":envoy_tar",
        ":rust_module_tar",
    ],
)

oci_push(
    name = "push",
    image = ":image",
    remote_tags = [],
    repository = "index.docker.io/palermo/istio-proxy",
)

oci_load(
    name = "load",
    image = ":image",
    repo_tags = ["palermo/istio-proxy:latest"],
)

container_structure_test(
    name = "image_test",
    configs = ["testdata/image.yaml"],
    image = ":image",
    local = True,
)
