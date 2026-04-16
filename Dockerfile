# syntax=docker/dockerfile:1.4
FROM rust:1.75-bookworm AS builder

# Install required dependencies
RUN apt-get update && apt-get install -y cmake pkg-config libssl-dev clang

WORKDIR /usr/src/atlas

# Copy workspace manifests and source code (no data — fetched at runtime)
COPY Cargo.toml Cargo.lock ./
COPY crates ./crates

# Build the release binaries
RUN cargo build --release -p atlas-server -p atlas-ingest

# Create lightweight production runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*

# Install pmtiles CLI for extracting Nigeria tiles
RUN curl -L -o /tmp/pmtiles.tar.gz \
        https://github.com/protomaps/go-pmtiles/releases/download/v1.20.0/go-pmtiles_1.20.0_linux_amd64.tar.gz \
    && tar -xzf /tmp/pmtiles.tar.gz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/pmtiles \
    && rm /tmp/pmtiles.tar.gz

WORKDIR /usr/src/atlas

COPY --from=builder /usr/src/atlas/target/release/atlas-server /usr/local/bin/atlas-server
COPY --from=builder /usr/src/atlas/target/release/atlas-ingest /usr/local/bin/atlas-ingest

# Copy scripts and set permissions
COPY scripts/fetch-nigeria-data.sh ./scripts/fetch-nigeria-data.sh
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./scripts/fetch-nigeria-data.sh ./entrypoint.sh

ENV HOST=0.0.0.0
ENV PORT=3001

EXPOSE 3001
ENTRYPOINT ["./entrypoint.sh"]

