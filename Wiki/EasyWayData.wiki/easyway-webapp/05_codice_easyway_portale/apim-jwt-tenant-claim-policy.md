---
id: ew-apim-jwt-tenant-claim-policy
title: APIM – JWT Validate & Tenant Claim
summary: Esempio di policy APIM per validazione JWT e mappatura tenant
status: draft
owner: team-platform
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email]
entities: []
---

Obiettivo
- Validare il JWT in ingresso e derivare il tenant da un claim applicativo (es. `ew_tenant_id`).
- Opzionale: impostare un header interno per compatibilità con sistemi legacy o per auditing.

Esempio di policy (inbound)
```sql
<policies>
  <inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Invalid token">
      <openid-config url="https://login.microsoftonline.com/{TENANT_ID}/v2.0/.well-known/openid-configuration" />
      <required-claims>
        <claim name="ew_tenant_id" match="any">
          <value>.*</value>
        </claim>
      </required-claims>
      <audiences>
        <audience>api://your-app-id</audience>
      </audiences>
    </validate-jwt>

    <!-- Opzionale: header interno, non esposto ai client -->
    <set-header name="X-Tenant-Id" exists-action="override">
      <value>@(((Jwt)context.Variables["jwt"]).Claims["ew_tenant_id"])</value>
    </set-header>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
```sql

Note
- Il backend EasyWay non richiede più `X-Tenant-Id` dal client; legge il tenant dai claim del token.
- L’header impostato da APIM può servire per audit/troubleshooting, ma non è necessario.
- Usa prodotti/policy APIM per rate‑limit multi‑tenant, IP allowlist e mTLS secondo necessità.





