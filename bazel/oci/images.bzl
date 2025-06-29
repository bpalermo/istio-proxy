load("@rules_oci//oci:pull.bzl", "oci_pull")

def oci_images():
    oci_pull(
        name = "distroless_cc_debian12_nonroot",
        digest = "sha256:a3c413a866ff27d0ae9e8555fd7c29991799aba085d1d7eb3348acac171a1752",
        image = "gcr.io/distroless/cc-debian12",
        platforms = [
            "linux/amd64",
            "linux/arm64/v8",
        ],
    )
