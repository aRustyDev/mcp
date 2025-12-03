# Project Views

Views provide different perspectives on the same project data. Each view filters, groups, or visualizes items differently.

> **Note**: Views must be created manually through the GitHub UI. The API does not support view creation.

## Recommended Views

### Core Views

| View | Layout | Purpose | Configuration |
|------|--------|---------|---------------|
| **Overview** | Table | All items with key fields visible | No filter, show all fields |
| **Kanban** | Board | Track work by status | Group by Status |
| **Roadmap** | Roadmap | Timeline planning | Filter: has start/end date |

### Development Views

| View | Layout | Purpose | Configuration |
|------|--------|---------|---------------|
| **By Language** | Table | Tech stack distribution | Group by Language field |
| **By Category** | Table | Server functionality | Group by Category field |
| **Transport Work** | Board | Transport implementation | Filter: Transport Status ≠ complete, Group by Source Transport |
| **Docker Pipeline** | Board | Container progress | Group by Docker Phase |
| **Rust Rewrites** | Board | Rust implementation | Filter: Rust Phase ≠ not-planned, Group by Rust Phase |

### Quality Views

| View | Layout | Purpose | Configuration |
|------|--------|---------|---------------|
| **Documentation** | Board | Doc coverage | Group by Docs Phase |
| **CI/CD Setup** | Table | Pipeline status | Group by CI-CD Phase |
| **Comparison Matrix** | Table | Dense overview | Show all phase fields |

## Creating Views

1. Open the project: https://github.com/users/aRustyDev/projects/22
2. Click the `+` button next to existing views
3. Select layout type (Table, Board, or Roadmap)
4. Configure:
   - **Name**: Use names from the table above
   - **Filter**: Add filter conditions
   - **Group**: Set grouping field
   - **Columns**: Show/hide fields

### View Configuration Examples

#### Docker Pipeline (Board)
```
Layout: Board
Group by: Docker Phase
Columns visible: Title, Server Name, Category, Priority
Sort: Priority (descending)
```

#### Comparison Matrix (Table)
```
Layout: Table
Filter: none
Columns: Server Name, Language, Source Transport, Transport Status,
         Docker Phase, Rust Phase, Docs Phase, CI-CD Phase
Sort: Server Name (ascending)
```

#### Rust Rewrites (Board)
```
Layout: Board
Filter: Rust Phase != "not-planned"
Group by: Rust Phase
Columns: Title, Server Name, Language, Effort Estimate
Sort: Priority (descending)
```

## View Best Practices

1. **Don't duplicate data**: Views slice the same items differently
2. **Keep defaults simple**: The Overview should show everything
3. **Use filters sparingly**: Complex filters are hard to maintain
4. **Name descriptively**: View names should indicate their purpose
5. **Consider mobile**: Board views work better on small screens
