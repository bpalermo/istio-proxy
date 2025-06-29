load("@rules_oci//oci:pull.bzl", "oci_pull")

def oci_images():
    oci_pull(
        name = "distroless_base_nossl_debian12_nonroot",
        digest = "sha256:fa7b50f111719aaf5f7435383b6d05f12277f3ce9514bc0a62759374a04d6bae",
        image = "gcr.io/distroless/base-nossl-debian12",
        platforms = [
            "linux/amd64",
            "linux/arm64/v8",
        ],
    )
