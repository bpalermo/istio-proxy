FROM gcr.io/distroless/static-debian12:nonroot
ADD envoy /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/envoy"]
