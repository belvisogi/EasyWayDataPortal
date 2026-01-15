# Agent Integration Pattern: Final GEDI Review

## 🦗 Il Pattern "Grillo Parlante"

**Regola**: Tutti gli agent EasyWayDataPortal DEVONO chiamare `agent_gedi` a fine lavoro per feedback filosofico.

## 🎯 Perché?

**agent_gedi** è il "Guardian EasyWay Delle Intenzioni" - custode del manifesto e dei principi:
- Qualità > Velocità
- Misuriamo due, tagliamo una
- Il percorso conta
- Lasciare impronta tangibile
- "Non ne parliamo, risolviamo" (Velasco)

## 📋 Come Implementare

### Pattern Standard

Ogni agent alla fine del suo lavoro:

```javascript
// 1. Completa work
agent_xxx.completeTask();

// 2. Chiama GEDI per review filosofica
const gediReview = await agent_gedi.review({
  agent: "agent_xxx",
  action_completed: "db-table:create",
  summary: "Created CUSTOMERS table with RLS",
  artifacts: [
    "db/migrations/V12__customers.sql",
    "Wiki/01_database_architecture/tables/customers.md"
  ]
});

// 3. Log feedback (NON blocca)
console.log("🦗 GEDI says:", gediReview.message);

// 4. Ritorna risultato (proceed always)
return agent_xxx.result;
```

### Output GEDI

```json
{
  "principle_invoked": "tangible_legacy",
  "severity": "gentle",
  "message": "📝 GEDI: Ottimo lavoro! La tabella è ben documentata. Per il futuro, considera di aggiungere esempi di query nella Wiki - altri DBA potranno imparare.",
  "bypass_allowed": true,
  "documentation_required": false
}
```

## 🤖 Agents da Aggiornare

### ✅ Già Implementato
- `agent_dba` - richiama gedi per guardrails review

### 🔄 Da Implementare
- [ ] `agent_docs_sync` - review doc changes
- [ ] `agent_backend` - review API changes
- [ ] `agent_frontend` - review UX decisions
- [ ] `agent_security` - review security choices
- [ ] `agent_datalake` - review data quality gates
- [ ] `agent_synapse` - review Synapse migrations
- [ ] Tutti gli altri agent...

## 📝 Template Manifest Update

Aggiungi al manifest di ogni agent:

```json
{
  "actions": [...],
  "post_action_hooks": [
    {
      "hook": "gedi_philosophical_review",
      "agent": "agent_gedi",
      "when": "always",
      "blocking": false,
      "description": "Feedback filosofico post-azione"
    }
  ],
  "relationships": {
    "reports_to": ["agent_gedi"],
    "description": "Tutti gli agent consultano GEDI per allineamento filosofico"
  }
}
```

## 🎯 Benefit

1. **Coerenza Filosofica**: Tutti gli agent seguono manifesto EasyWay
2. **Quality Reminder**: "Did we rush?" "Is this maintainable?"
3. **Learning**: GEDI suggerisce miglioramenti per prossime iterazioni
4. **Tracciabilità**: Log di tutte le decisioni con philosophical context
5. **Never Blocking**: GEDI consiglia, non blocca - sei TU che decidi

## 🔄 Integration Flow

```
agent_xxx lavora
    ↓
Completa task
    ↓
Chiama agent_gedi per review
    ↓
GEDI: "💙 Bello! Considera X per il futuro"
    ↓
agent_xxx logga feedback
    ↓
Ritorna risultato al chiamante
```

**Niente è bloccato** - GEDI è sempre presente ma mai bloccante.

## 📊 Monitoring

Track GEDI feedback per vedere pattern team:

```sql
SELECT 
  agent_name,
  COUNT(*) as gedi_reviews,
  COUNT(CASE WHEN severity = 'warning' THEN 1 END) as warnings,
  COUNT(CASE WHEN documentation_required THEN 1 END) as docs_missing
FROM gedi_review_log
GROUP BY agent_name
ORDER BY warnings DESC;
```

Se un agent riceve molti warning → training opportunity!

---

**Status**: Pattern da implementare in tutti gli agent  
**Owner**: Agent developers  
**GEDI Approval**: 💙 "Amo questo! È esattamente lo spirito EasyWay"
