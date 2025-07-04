# Copyright 2016 Google Inc. All Rights Reserved.
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
workspace(name = "io_istio_proxy")

load("//bazel:repositories.bzl", "repositories")

repositories()

load("@envoy//bazel:api_binding.bzl", "envoy_api_binding")

local_repository(
    name = "envoy_build_config",
    # Relative paths are also supported.
    path = "bazel/extension_config",
)

envoy_api_binding()

load("@envoy//bazel:api_repositories.bzl", "envoy_api_dependencies")

envoy_api_dependencies()

load("@rules_oci//oci:dependencies.bzl", "rules_oci_dependencies")

rules_oci_dependencies()

load("@envoy//bazel:repositories.bzl", "envoy_dependencies")

envoy_dependencies()

load("@envoy//bazel:repositories_extra.bzl", "envoy_dependencies_extra")

envoy_dependencies_extra(ignore_root_user_error = True)

load("@envoy//bazel:python_dependencies.bzl", "envoy_python_dependencies")

envoy_python_dependencies()

load("@base_pip3//:requirements.bzl", "install_deps")

install_deps()

load("@envoy//bazel:dependency_imports.bzl", "envoy_dependency_imports")

envoy_dependency_imports()

load("@envoy//bazel:dependency_imports_extra.bzl", "envoy_dependency_imports_extra")

envoy_dependency_imports_extra()

load("//bazel/rust:crates_repository.bzl", "crates_repository")

crates_repository()

load("@crate_index//:defs.bzl", "crate_repositories")

crate_repositories()

load("@container_structure_test//:repositories.bzl", "container_structure_test_register_toolchain")

container_structure_test_register_toolchain(name = "cst")

load("@rules_oci//oci:repositories.bzl", "oci_register_toolchains")

oci_register_toolchains(name = "oci")

load("//bazel/oci:images.bzl", "oci_images")

oci_images()
