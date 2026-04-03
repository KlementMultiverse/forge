# Upstream Proxy System

## Architecture

HTTPS CONNECT proxy on localhost, tunnelled to gateway over WebSocket. Routes outbound container traffic without exposing credentials to agent loop.

## Initialization (6-Step, Fail-Safe)

1. Guard env vars
2. Read session token
3. Set non-dumpable via prctl (blocks ptrace)
4. Download CA bundle
5. Start relay TCP server
6. Unlink token file (only after relay confirms listening)

## Two-Phase Connection

Phase 1: Accumulate CONNECT header. Phase 2: Pump bytes to WebSocket (buffer pending data until ws.onopen).

Race condition fix: TCP may coalesce CONNECT header + TLS ClientHello into one packet.

## Hand-Rolled Protobuf Encoding

Manual encoding for message framing. Content-Type: application/proto required.

## Environment Variable Propagation

HTTPS_PROXY, NO_PROXY, SSL_CERT_FILE, NODE_EXTRA_CA_CERTS, REQUESTS_CA_BUNDLE, CURL_CA_BUNDLE.

NO_PROXY lists Anthropic three ways for different runtime parsing.

## Security

`prctl(PR_SET_DUMPABLE, 0)` blocks ptrace heap inspection. TLS corruption guard: never write plaintext error into active TLS connection.

## Keepalive & Chunking

Zero-length chunks every 30s. 512KB chunk size limit for Envoy buffer cap.
