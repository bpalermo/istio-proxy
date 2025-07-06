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
    "@istio_proxy//source/extensions/common/workload_discovery:api_lib",  # Experimental: WIP
    "@istio_proxy//source/extensions/filters/http/alpn:config_lib",
    "@istio_proxy//source/extensions/filters/http/istio_stats",
    "@istio_proxy//source/extensions/filters/http/peer_metadata:filter_lib",
    "@istio_proxy//source/extensions/filters/network/metadata_exchange:config_lib",
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

# will be downloaded during the CI build
exports_files([
    "pilot-agent",
    "envoy_bootstrap.json"
])

pkg_tar(
    name = "pilot_agent_tar",
    srcs = ["//:pilot-agent"],
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

pkg_tar(
    name = "envoy_bootstrap_template_tar",
    extension = "tar.gz",
    files = {
        "//:envoy_bootstrap.json": "/usr/lib/istio/envoy/envoy_bootstrap_tmpl.json",
    },
    modes = {
        "/usr/lib/istio/envoy/envoy_bootstrap_tmpl.json": "0444",
    },
    owners = {
        "/usr/lib/istio/envoy/envoy_bootstrap_tmpl.json": "65532.65532",
    },
    visibility = ["//visibility:public"],
)

oci_image(
    name = "image",
    base = "@distroless_cc_debian12_nonroot",
    entrypoint = ["/usr/local/bin/pilot-agent"],
    env = {
        "ENVOY_DYNAMIC_MODULES_SEARCH_PATH": "/usr/local/lib",
    },
    tars = [
        ":envoy_tar",
        ":pilot_agent_tar",
        ":envoy_bootstrap_template_tar",
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
