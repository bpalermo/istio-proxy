load("@rules_shell//shell:sh_library.bzl", "sh_library")

# For the shellcheck aspect (--config=lint). The update scripts are run
# directly, not with `bazel run`: they find the repository from their own path,
# which under `bazel run` is the runfiles tree. The workspace status script is
# run by Bazel itself.
sh_library(
    name = "scripts",
    srcs = glob(["*.sh"]) + ["bazel_get_workspace_status"],
)
