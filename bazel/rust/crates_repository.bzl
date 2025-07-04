load("@rules_rust//crate_universe:defs.bzl", "crate", _crates_repository = "crates_repository")

def crates_repository():
    _crates_repository(
        name = "crate_index",
        cargo_lockfile = "//:Cargo.lock",
        lockfile = "//:Cargo.Bazel.lock",
        packages = {
            "regex": crate.spec(
                version = "1.11.1",
            ),
        },
    )
