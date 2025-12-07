---
id: 6ab50022-3628-416e-8651-e6ca3ac3d940
title: "Phase 12: Testing - Mock Harness"
status: pending
depends_on:
  - cbf0ef37-c0c8-45f7-afe3-b89c274b4566  # phase-11
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 12: Testing - Mock Harness

## 1. Current State Assessment

- [ ] Check for existing mock infrastructure
- [ ] Review WireMock/mockserver usage
- [ ] Identify VCR/cassette recording needs
- [ ] Check for factory pattern implementations

### Existing Assets

None - mock infrastructure not yet created.

### Gaps Identified

- [ ] docker-compose.mocks.yml
- [ ] WireMock mappings
- [ ] Mock MCP server
- [ ] Factory patterns per language
- [ ] VCR/cassette infrastructure
- [ ] Mock harness workflow

---

## 2. Contextual Goal

Build comprehensive mock infrastructure for testing services in isolation. This includes HTTP mocking with WireMock, a mock MCP server for client testing, data factories for generating test fixtures, and VCR-style recording for external API interactions. The harness should be reusable across test types and languages.

### Success Criteria

- [ ] docker-compose.mocks.yml with all mock services
- [ ] Mock MCP server functional
- [ ] Factories implemented for Python, TS, Rust
- [ ] VCR recording infrastructure working
- [ ] Workflow to spin up mock environment

### Out of Scope

- Chaos injection (Phase 13)
- Production-like load testing

---

## 3. Implementation

### 3.1 docker-compose.mocks.yml

```yaml
version: '3.8'

services:
  wiremock:
    image: wiremock/wiremock:latest
    ports:
      - "8080:8080"
    volumes:
      - ./wiremock:/home/wiremock

  mock-mcp-server:
    build:
      context: ./mock-mcp-server
    ports:
      - "3000:3000"
    environment:
      - MCP_DELAY_MS=0
      - MCP_ERROR_RATE=0

  mockserver:
    image: mockserver/mockserver:latest
    ports:
      - "1080:1080"
```

### 3.2 Mock MCP Server

```rust
// mock-mcp-server/src/main.rs
struct MockConfig {
    tools: Vec<Tool>,
    resources: Vec<Resource>,
    delay_ms: u64,
    error_rate: f32,
    custom_responses: HashMap<String, Value>,
}
```

### 3.3 Factory Patterns

**Python (factory_boy)**:
```python
class ToolFactory(factory.Factory):
    class Meta:
        model = Tool

    name = factory.Faker('word')
    description = factory.Faker('sentence')
```

**TypeScript (fishery)**:
```typescript
export const toolFactory = Factory.define<Tool>(() => ({
  name: faker.word.noun(),
  description: faker.lorem.sentence(),
}));
```

**Rust (fake)**:
```rust
impl Dummy<Faker> for Tool {
    fn dummy_with_rng<R: Rng + ?Sized>(_: &Faker, rng: &mut R) -> Self {
        Tool {
            name: Word().fake_with_rng(rng),
            description: Sentence(3..5).fake_with_rng(rng),
        }
    }
}
```

### 3.4 VCR Infrastructure

| Language | Library | Format |
|----------|---------|--------|
| Python | vcrpy | YAML cassettes |
| TypeScript | nock | JSON recordings |
| Rust | rvcr | JSON cassettes |

### 3.5 mock-harness.yml

```yaml
name: Mock Harness

on:
  workflow_call:
  workflow_dispatch:

jobs:
  start-mocks:
    runs-on: ubuntu-latest
    outputs:
      wiremock-url: http://localhost:8080
      mcp-url: http://localhost:3000

    steps:
      - uses: actions/checkout@v4

      - name: Start mock services
        run: docker compose -f docker-compose.mocks.yml up -d

      - name: Wait for services
        run: |
          # Health checks
```

---

## 4. Review & Validation

- [ ] All mock services start correctly
- [ ] Mock MCP server responds to requests
- [ ] Factories generate valid data
- [ ] VCR recording and playback works
- [ ] Implementation tracking checklist updated
