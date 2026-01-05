---
id: ew-query-in-src-queries
title: query in src queries
tags: [domain/control-plane, layer/howto, audience/dev, privacy/internal, language/it, queries]
owner: team-platform
summary: TODO - aggiungere un sommario breve.
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
1. users_select_by_tenant.sql
```sql
SELECT * FROM PORTAL.USERS WHERE tenant_id = @tenant_id AND is_active = 1;
```sql

2. users_update.sql
```sql
UPDATE PORTAL.USERS
SET email = @email,
    display_name = @display_name,
    profile_id = @profile_id,
    is_active = @is_active,
    updated_at = SYSUTCDATETIME()
WHERE user_id = @user_id AND tenant_id = @tenant_id;

SELECT * FROM PORTAL.USERS WHERE user_id = @user_id AND tenant_id = @tenant_id;
```sql

3. users_deactive.sql
```sql
UPDATE PORTAL.USERS
SET is_active = 0,
    updated_at = SYSUTCDATETIME()
WHERE user_id = @user_id AND tenant_id = @tenant_id;
```sql

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?







