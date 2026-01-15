# db-deploy-ai

> **Stop fighting with Flyway. Database migrations that just work.**

AI-friendly database migration tool designed for **humans and AI agents**. Simple setup, smart errors, visual schemas. Built by developers who were tired of XML config hell.

[![Status](https://img.shields.io/badge/status-beta-blue.svg)](https://github.com/easywaydata/db-deploy-ai)
[![SQL Server](https://img.shields.io/badge/sql%20server-2019%2B-orange.svg)](https://www.microsoft.com/sql-server)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🎯 Why db-deploy-ai?

If you've ever spent **2 hours configuring Flyway** just to run a simple migration, this tool is for you.

### The Problem

Traditional migration tools were built in the 2000s, before:
- ✅ JSON became the universal format
- ✅ AI agents started writing code
- ✅ Developers expected **good error messages**
- ✅ Visual tools became standard

Result? You spend more time **fighting your migration tool** than actually migrating.

### The Solution

**db-deploy-ai** is a fresh start:

| Pain Point | db-deploy-ai Solution |
|------------|----------------------|
| "2+ hours XML config" | ⚡ **5-minute JSON setup** |
| "Cryptic error: line 47" | 💡 **Smart errors with fix suggestions** |
| "Can't see my schema" | 🎨 **Interactive visual viewer** |
| "AI can't use Flyway" | 🤖 **JSON API, designed for AI** |
| "ERwin costs $$$" | 📋 **Free declarative blueprints** |

---

## 🚀 Quick Start (2 minutes)

### 1. Install
```bash
git clone https://github.com/easywaydata/db-deploy-ai
cd db-deploy-ai
npm install
```

### 2. Create your first migration
```bash
echo '{
  "connection": {
    "server": "localhost",
    "database": "mydb",
    "auth": {
      "username": "sa",
      "password": "MyPassword123"
    }
  },
  "statements": [{
    "id": "create_users_table",
    "sql": "CREATE TABLE users (id INT PRIMARY KEY, name NVARCHAR(100))"
  }]
}' | node src/cli.js apply
```

### 3. Done! ✅

No XML files.  
No complex config.  
Just JSON in, SQL out, database updated.

---

## ✨ Key Features

### 1. **Human-Friendly Errors**

**Flyway:**
```
ERROR: Validate failed: Migration checksum mismatch for migration version 2
```

**db-deploy-ai:**
```json
{
  "status": "error",
  "message": "Table 'users' already exists",
  "suggestion": "Add 'IF NOT EXISTS' or use --force to override",
  "context": {
    "statement_id": "create_users_table",
    "line": 3
  }
}
```

### 2. **Blueprint System** (ERwin Alternative)

Declarative schema in JSON - version control friendly, AI readable:

```json
{
  "tables": [{
    "name": "users",
    "columns": [
      { "name": "id", "type": "INT", "primary_key": true },
      { "name": "email", "type": "NVARCHAR(255)", "unique": true }
    ],
    "indexes": [
      { "name": "idx_email", "columns": ["email"] }
    ]
  }]
}
```

Generate JSON from existing DB (Reverse Engineer):
```bash
npm run blueprint:generate -- --output schema.json --database MyAppDB
```

Generate SQL from Blueprint (Coming Soon):
```bash
npm run blueprint:to-sql < schema.json > create_schema.sql
```

### 3. **Visual Schema Viewer**

See your database at a glance:
```bash
npm run viewer
# Opens interactive ER diagram in browser
```

### 4. **AI-Native Design**

Perfect for AI agents (Claude, GPT, Copilot):
- JSON input/output (no XML parsing)
- Structured errors (parseable)
- Blueprint system (declarative, diff-friendly)

Example AI workflow:
```javascript
// AI reads blueprint
const schema = JSON.parse(await readFile('schema.json'));

// AI adds column
schema.tables[0].columns.push({
  name: 'created_at',
  type: 'DATETIME',
  default: 'GETDATE()'
});

// AI applies change
const sql = await generateSQL(schema);
await applyMigration(sql);
```

---

## 📊 vs Flyway / Liquibase

| Feature | Flyway | Liquibase | **db-deploy-ai** |
|---------|--------|-----------|------------------|
| Setup time | 2+ hours | 2+ hours | **5 minutes** ⚡ |
| Config format | XML/Props | XML/YAML | **JSON** 🎯 |
| Error quality | Cryptic | Cryptic | **Suggestions** 💡 |
| Visual schema | ❌ | ❌ | **✅** 🎨 |
| Blueprint (ERwin-like) | ❌ | ❌ | **✅** 📋 |
| AI integration | ❌ | ❌ | **✅ Native** 🤖 |
| Transaction mgmt | Manual | Manual | **Automatic** ⚙️ |
| Dry-run | Limited |  Limited | **Full validation** ✅ |
| Price | Free | Free | **Free** 💰 |

**Bottom line**: Flyway for enterprise compliance. **db-deploy-ai for developer happiness.**

---

## 🎯 Use Cases

### 1. **Solo Developer / Side Project**
> "I don't want to spend my weekend configuring Flyway. I just want to migrate my DB."

✅ 5-minute setup, get back to building

### 2. **Small Team**
> "Our junior devs keep breaking migrations. We need better error messages."

✅ Smart errors guide them to fix issues

### 3. **AI-First Development**
> "I use Cursor/Copilot. My tools should work with AI, not against it."

✅ JSON API designed for LLMs

### 4. **Blueprint-Driven Teams**
> "ERwin is $5k/seat. We just need declarative schemas."

✅ Free blueprint system, version-controlled

---

## 📚 Documentation

- **[Getting Started](docs/getting-started.md)** - Complete setup guide
- **[Blueprint Guide](docs/blueprint.md)** - Declarative schema management
- **[API Reference](docs/api.md)** - JSON contract details
- **[Migration from Flyway](docs/flyway-migration.md)** - 10-minute switch guide
- **[AI Integration](docs/ai-integration.md)** - Use with LLMs

---

## 🚧 Roadmap

### ✅ v0.1 (Current - Beta)
- [x] JSON API for migrations
- [x] Smart error reporting
- [x] Blueprint system (basics)
- [x] SQL Server support

### 🔜 v0.2 (Next - 4 weeks)
- [x] Blueprint generator (reverse engineer) ✅
- [ ] Blueprint → SQL generator
- [ ] Visual schema viewer (interactive)
- [ ] Validation rules

### 🔮 v1.0 (Production - 3 months)
- [ ] PostgreSQL support
- [ ] MySQL support
- [ ] Migration auto-generation
- [ ] Web dashboard

---

## 💬 Community & Support

- **Questions?** [Open an issue](https://github.com/easywaydata/db-deploy-ai/issues)
- **Ideas?** [Start a discussion](https://github.com/easywaydata/db-deploy-ai/discussions)
- **Updates:** Follow [@dbdeployai](https://twitter.com/dbdeployai) on Twitter

---

## 🤝 Contributing

We welcome contributions! Check out:
- [Contributing Guide](CONTRIBUTING.md)
- [Good First Issues](https://github.com/easywaydata/db-deploy-ai/labels/good%20first%20issue)
- [Development Setup](docs/development.md)

---

## 📖 Example: Complete Workflow

```bash
# 1. Create blueprint
cat > schema.json << EOF
{
  "tables": [{
    "name": "products",
    "columns": [
      { "name": "id", "type": "INT", "identity": true, "primary_key": true },
      { "name": "title", "type": "NVARCHAR(200)" },
      { "name": "price", "type": "DECIMAL(10,2)" }
    ]
  }]
}
EOF

# 2. Generate SQL
npm run blueprint:generate < schema.json > create_products.sql

# 3. Apply migration
cat create_products.sql | npm run migrate

# 4. Verify
npm run diff
# Output: ✅ Schema matches blueprint
```

---

## 🙏 Acknowledgments

Inspired by:
- **Flyway** - Showed us database versioning matters
- **Liquibase** - Taught us the power of declarative
- **Prisma** - Proved developer experience can be delightful

Built by developers frustrated with 2000s-era tools, for developers building in 2026.

---

## 📄 License

MIT - See [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Stop fighting. Start migrating.</strong><br>
  <a href="https://github.com/easywaydata/db-deploy-ai">Get Started →</a>
</p>
