
## Custom Headers
- Debug logging
- Tracing
- Auth Headers (Bearer, JWT, etc)
- Cookies
- transport (streamed/http, sse, stdio)
- backend (use plugin framework)
  - DB
- feedback / user-in-the-loop
- agents (testing/healthchecks/background work)
- tests
- healthchecks
- llm_endpoint
- llm_model
- llm_platform / llm_api
- llm_*
- proxy config
- protocol (tcp, udp, websocket, etc)
- --config flag (pass config file)
- --example-config <mcp-client> (write mcp-client config for this tool to stdout; ie zed, claude code, vscode, etc)

## Repo features

- Markdown badges
  - ![Claude](https://img.shields.io/badge/Claude-D97757?style=for-the-badge&logo=claude&logoColor=white)
  - ![aRustyDev](https://img.arusty.dev/badge/arustydev?style=for-the-badge&logo=<fooBar>&logoColor=white)
  - [markbadge](https://markbadge.com/static)
    - transport support status (R/Y/G) (Stdio/SSE/HTTP)
    - healthcheck support status (R/Y/G) (None/Some/Complete)
    - container support status (R/Y/G) (None/Dockerfile/PublishedContainer)
    - pluggable backend support status (R/Y/G) (False/WIP/True)
    - pluggable llm support status (R/Y/G) (False/WIP/True)
