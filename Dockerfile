# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM rust:1.85-bookworm AS builder

WORKDIR /build

# Cache dependencies first
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release

# ---------- Runtime stage ----------
FROM debian:bookworm-slim

# reqwest uses OpenSSL for TLS
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /build/target/release/aurorium /usr/local/bin/aurorium

# Runtime data (assets, db, logs) lives here; mount a volume for persistence
RUN mkdir -p /app/data /app/logs

EXPOSE 12369

# Non-root user
RUN useradd --create-home --uid 10001 aurorium \
    && chown -R aurorium:aurorium /app
USER aurorium

ENTRYPOINT ["aurorium"]