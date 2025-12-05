---
id: 6d0e0e40-1c80-4d57-aef2-e2da53cdd416
title: "MCP Testing Taxonomy"
type: reference
---

# MCP Server Testing Taxonomy

## Overview

Comprehensive testing strategy for Model Context Protocol (MCP) servers covering protocol conformance, functional correctness, security, performance, and reliability.

---

## 1. Protocol Conformance Testing

### 1.1 JSON-RPC 2.0 Compliance

| Test ID | Test Case | Input | Expected |
|---------|-----------|-------|----------|
| JSONRPC-001 | Valid request format | `{"jsonrpc":"2.0","id":1,"method":"..."}` | Accepted |
| JSONRPC-002 | Missing jsonrpc field | `{"id":1,"method":"..."}` | Error -32600 |
| JSONRPC-003 | Invalid jsonrpc version | `{"jsonrpc":"1.0",...}` | Error -32600 |
| JSONRPC-004 | Null id for notification | `{"jsonrpc":"2.0","method":"..."}` | No response |
| JSONRPC-005 | String id handling | `{"id":"abc",...}` | Response with same id |
| JSONRPC-006 | Batch requests | `[{...},{...}]` | Batch response |
| JSONRPC-007 | Empty batch | `[]` | Error -32600 |

#### Error Code Verification

| Code | Meaning | When to Return |
|------|---------|----------------|
| -32700 | Parse error | Invalid JSON |
| -32600 | Invalid request | Malformed request object |
| -32601 | Method not found | Unknown method |
| -32602 | Invalid params | Wrong arguments |
| -32603 | Internal error | Server error |
| -32000 to -32099 | Server error | Implementation-defined |

### 1.2 MCP Protocol Compliance

#### Initialization Sequence

```
┌─────────┐                    ┌─────────┐
│  Client │                    │  Server │
└────┬────┘                    └────┬────┘
     │                              │
     │──── initialize ─────────────>│
     │                              │
     │<─── initialize result ───────│
     │                              │
     │──── initialized ────────────>│
     │                              │
     │     (ready for requests)     │
```

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| MCP-INIT-001 | Valid initialize request | Success with capabilities |
| MCP-INIT-002 | Missing clientInfo | Error or default handling |
| MCP-INIT-003 | Unsupported protocol version | Error with supported versions |
| MCP-INIT-004 | Request before initialize | Error -32002 (not initialized) |
| MCP-INIT-005 | Double initialize | Error or idempotent |
| MCP-INIT-006 | initialized notification | No response, ready state |

### 1.3 Schema Validation

```yaml
validation_targets:
  requests:
    - initialize params match InitializeRequest schema
    - tools/call params match CallToolRequest schema
    - resources/read params match ReadResourceRequest schema

  responses:
    - initialize result matches InitializeResult schema
    - tools/list result matches ListToolsResult schema
    - Content objects have required type field

  error_objects:
    - Required: code (integer), message (string)
    - Optional: data (any)
```

---

## 2. Functional Testing

### 2.1 Tool Testing

#### Tool Discovery (tools/list)

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| TOOL-LIST-001 | List all tools | Array of tool definitions |
| TOOL-LIST-002 | Empty tools list | Empty array (not error) |
| TOOL-LIST-003 | Tool metadata complete | name, description, inputSchema present |
| TOOL-LIST-004 | inputSchema is valid JSON Schema | Parseable schema |
| TOOL-LIST-005 | Pagination (cursor) | Correct page handling |

#### Tool Invocation (tools/call)

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| TOOL-CALL-001 | Valid tool call | Success with content |
| TOOL-CALL-002 | Unknown tool name | Error -32601 or MCP error |
| TOOL-CALL-003 | Missing required argument | Error -32602 |
| TOOL-CALL-004 | Wrong argument type | Error -32602 |
| TOOL-CALL-005 | Extra arguments | Ignored or error (per policy) |
| TOOL-CALL-006 | Empty arguments object | Valid if no required params |
| TOOL-CALL-007 | Null argument value | Per schema (nullable?) |

### 2.2 Resource Testing

#### Resource Discovery (resources/list)

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| RES-LIST-001 | List all resources | Array of resource definitions |
| RES-LIST-002 | Resource metadata | uri, name, mimeType present |
| RES-LIST-003 | URI scheme handling | file://, http://, custom:// |
| RES-LIST-004 | Pagination | Cursor-based pagination works |

#### Resource Reading (resources/read)

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| RES-READ-001 | Valid URI | Contents returned |
| RES-READ-002 | Unknown URI | Error -32002 |
| RES-READ-003 | Text resource | text field populated |
| RES-READ-004 | Binary resource | blob field (base64) |
| RES-READ-005 | Large resource | Chunking or streaming |

### 2.3 Prompt Testing

#### Prompt Discovery (prompts/list)

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| PROMPT-LIST-001 | List all prompts | Array of prompt definitions |
| PROMPT-LIST-002 | Prompt metadata | name, description, arguments |
| PROMPT-LIST-003 | Required vs optional args | Clearly marked |

---

## 3. Transport Testing

### 3.1 stdio Transport

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| STDIO-001 | Line-delimited JSON | Each message on one line |
| STDIO-002 | Large message buffering | No truncation |
| STDIO-003 | UTF-8 encoding | Correct handling |
| STDIO-004 | EOF handling | Graceful shutdown |
| STDIO-005 | stderr for logging | Doesn't pollute stdout |

### 3.2 HTTP/SSE Transport

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| SSE-001 | Event stream format | `data: {...}\n\n` |
| SSE-002 | Event type field | Correct event types |
| SSE-003 | Keep-alive | Connection stays open |
| SSE-004 | Reconnection | Client can reconnect |
| SSE-005 | CORS headers | Proper cross-origin support |

### 3.3 WebSocket Transport

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| WS-001 | Connection establishment | Successful handshake |
| WS-002 | Message framing | Text frames, JSON content |
| WS-003 | Ping/pong | Keep-alive works |
| WS-004 | Close handling | Clean disconnect |
| WS-005 | Reconnection | State recovery |

---

## 4. Security Testing

### 4.1 Input Validation

| Test ID | Test Case | Attack Vector | Expected |
|---------|-----------|---------------|----------|
| SEC-INP-001 | Path traversal | `../../../etc/passwd` | Blocked |
| SEC-INP-002 | Command injection | `; rm -rf /` | Sanitized |
| SEC-INP-003 | SQL injection | `' OR 1=1 --` | Escaped |
| SEC-INP-004 | XSS in output | `<script>alert(1)</script>` | Escaped |
| SEC-INP-005 | XXE injection | External entity | Blocked |
| SEC-INP-006 | SSRF | `http://169.254.169.254/` | Blocked |

### 4.2 Rate Limiting

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| SEC-RATE-001 | Normal usage | Allowed |
| SEC-RATE-002 | Exceed limit | 429 or error response |
| SEC-RATE-003 | Rate limit reset | Access restored after window |

### 4.3 Fuzzing Targets

```yaml
fuzzing_targets:
  json_parsing:
    tool: cargo-fuzz / atheris / jazzer
    inputs:
      - Malformed JSON
      - Deeply nested objects
      - Very long strings
      - Invalid UTF-8

  protocol_messages:
    inputs:
      - Random method names
      - Random params structures
      - Edge case values

  tool_arguments:
    inputs:
      - Generated per inputSchema
      - Boundary values
      - Type confusion
```

---

## 5. Performance Testing

### 5.1 Latency Benchmarks

| Metric | Target | Measurement |
|--------|--------|-------------|
| p50 latency | < 50ms | Median response time |
| p95 latency | < 200ms | 95th percentile |
| p99 latency | < 500ms | 99th percentile |
| Cold start | < 2s | First request after start |

### 5.2 Throughput Benchmarks

| Scenario | Target | Duration |
|----------|--------|----------|
| Sustained load | 100 req/s | 10 minutes |
| Peak load | 500 req/s | 1 minute |
| Burst | 1000 req/s | 10 seconds |

### 5.3 Resource Usage

| Metric | Idle | Under Load | Limit |
|--------|------|------------|-------|
| Memory | < 50MB | < 200MB | 512MB |
| CPU | < 1% | < 50% | 80% |
| Connections | 0 | < 100 | 1000 |

---

## 6. Reliability Testing

### 6.1 Error Handling

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| REL-ERR-001 | Tool throws exception | JSON-RPC error response |
| REL-ERR-002 | Resource not found | Proper error code |
| REL-ERR-003 | Network timeout | Error, not hang |
| REL-ERR-004 | Partial failure | Other tools still work |

### 6.2 Graceful Shutdown

| Test ID | Test Case | Expected |
|---------|-----------|----------|
| REL-SHUT-001 | SIGTERM | Pending requests complete |
| REL-SHUT-002 | SIGINT | Clean shutdown |
| REL-SHUT-003 | Shutdown timeout | Force terminate |

### 6.3 Chaos Testing

```yaml
chaos_scenarios:
  network:
    - Latency injection (100-500ms)
    - Packet loss (1-10%)
    - Connection reset
    - DNS failure

  resource:
    - CPU stress (90%)
    - Memory pressure (80%)
    - Disk full
    - File descriptor exhaustion

  dependency:
    - External API down
    - Database unavailable
    - Slow responses
```

---

## 7. Test Infrastructure

### 7.1 Mock Harness Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Test Execution                           │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Mock Servers │    │   Fixtures    │    │  Recorders    │
│  - WireMock   │    │  - Factories  │    │  - VCR        │
│  - mockserver │    │  - Snapshots  │    │  - Cassettes  │
│  - Prism      │    │  - Seeds      │    │  - Replay     │
└───────────────┘    └───────────────┘    └───────────────┘
```

### 7.2 Test Data Factories

| Language | Library | Usage |
|----------|---------|-------|
| Python | factory_boy | `UserFactory.build()` |
| TypeScript | fishery | `userFactory.build()` |
| Rust | fake | `Faker.fake::<User>()` |

---

## 8. Test Tooling by Language

### 8.1 Rust

```yaml
testing:
  unit: cargo test
  integration: cargo test --test '*'
  coverage: cargo-llvm-cov, grcov
  benchmarks: criterion
  property: proptest
  fuzzing: cargo-fuzz
  mutation: cargo-mutants
```

### 8.2 Python

```yaml
testing:
  unit: pytest
  integration: pytest-asyncio
  coverage: coverage.py
  benchmarks: pytest-benchmark
  property: hypothesis
  fuzzing: atheris
  mutation: mutmut
```

### 8.3 TypeScript

```yaml
testing:
  unit: vitest, jest
  integration: vitest
  coverage: c8, istanbul
  benchmarks: tinybench
  property: fast-check
  mutation: stryker
```

---

## 9. CI/CD Integration

### 9.1 Quality Gates

| Gate | Threshold | Enforcement |
|------|-----------|-------------|
| Unit test pass | 100% | Block merge |
| Coverage | > 70% | Block merge |
| Integration pass | 100% | Block merge |
| Security issues | 0 critical | Block merge |
| Performance regression | < 10% | Warning |

---

## 10. External Resources

### Evaluation Platforms

- https://www.mcpevals.io/
- https://www.mcpevals.ai/
- https://mcp.scorecard.io/mcp

### Testing Guides

- https://mcpcat.io/guides/writing-unit-tests-mcp-servers/
- https://testomat.io/blog/mcp-server-testing-tools/

### Benchmarks

- https://deepwiki.com/modelscope/MCPBench/3.3-metrics-and-results
