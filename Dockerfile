FROM gcr.io/distroless/base-nossl-debian12:nonroot
COPY --chown=65532:65532 --chmod=755 envoy /usr/local/bin/
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/envoy"]
