conventional-commit "types"

feat | ✨ Features | minor |
| fix | 🐛 Bug Fixes | patch |
| hotfix | 🚑 Hotfixes | patch |
| security | 🔒 Security | patch |
| deps | 📦 Dependencies | patch |
| wip | (omitted) | - |
| release

- wip|🚧|👷(<scope>): Work in progress
- chore|🧹(<scope>): Maintenance tasks, dependencies
  - cleanup/trivial changes, syntax fixes, etc.
  - "Maintenance work and dependency updates"
- docs|📖(<scope>): Some sort of documentation change/addition
  - "Updating documentation and guides"
  - "Updating doc-comments (pydocs)"
- feat|✨(<scope>)[!]: a new feature
  - "Adding new functionality to the application"
- security|🔒(<scope>)[!]: a Security related change
- hotfix|🚑(<scope>)[!]: a Hotfix
- fix|🐛(<scope>)[!]: a bug fix
  - "Resolving issues and errors"
- perf|🏎️(<scope>)[!]: Performance improvements
  - "Optimizing application performance"
- refactor|🐙(<scope>)[!]: Code cleanup without changing functionality
  - "Improving code structure while maintaining the same behavior"
  - "no functional changes, but improves code structure or readability or organization"
- revert|⏪(<scope>): revert a previous commit
- style|🕺(<scope>): code style changes (Formatting, whitespace, semicolons)
  - "Code formatting changes without logic modifications"
- test|🧪|⚗️(<scope>)[!]: Adding or updating tests
  - "Adding test coverage and test improvements"
- deps|📦(<scope>): Dependency updates only
  - "Updating dependencies and packages"
- ai|🤖(<scope>): AI tooling changes
  - "Changing agent rules/context"
- ci|🔄(<scope>): CI/CD pipeline changes (including pre-commit)
  - "Continuous integration and deployment updates"
  - "automated dependency updates"
- build|🛠️|⚙️|🧰(<scope>)[!]: Build system changes
  - "Build configuration and tooling updates"

> '[!]|⛓️‍💥' signifies a breaking change with a 'type'; if a type does not have '[!]' after it in the above list it CANNOT have a breaking change.

conventional-commit "footers

- BREAKING CHANGE: a breaking change
- 'signed-off-by: John Doe <john.doe@example.com>': include a signed-off-by footer line for all committers
  - This should include at least "git.username <git.email>"
  - If an AI Tool is used, it should be signed as "Model or AI Tool Used <agent.id@arusty.dev>"

conventional-commit "scopes"

- Core: core, api, cli, config
- MCP: mcp, transport, tools, resources, prompts
- Infra: ci, docker, deps, docs
