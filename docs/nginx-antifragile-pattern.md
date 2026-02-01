# Nginx Antifragile Pattern

> **Principle**: Nginx configuration must never crash due to missing upstream services.

## The Problem

**Fragile Pattern** (Crashes on startup):
```nginx
location /api/qdrant/ {
    proxy_pass http://qdrant:6333/;  # ❌ Crashes if qdrant not found
}
```

**Error**:
```
nginx: [emerg] host not found in upstream "qdrant"
Container restart loop → 404 for all routes
```

---

## The Solution

### Pattern 1: Separate Reverse Proxy Layer (Recommended)

**Architecture**:
```
Internet → Traefik (handles all proxying) → Nginx (static files only)
                ↓
            Qdrant/N8N/etc
```

**Nginx Config** (Frontend only serves static files):
```nginx
server {
    listen 8080;
    root /usr/share/nginx/html;
    
    # SPA Routing
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # NO upstream proxies here!
}
```

**Traefik Config** (Handles all service routing):
```yaml
# docker-compose.yml
services:
  traefik:
    labels:
      - "traefik.http.routers.qdrant.rule=Host(`example.com`) && PathPrefix(`/api/qdrant`)"
      - "traefik.http.services.qdrant.loadbalancer.server.port=6333"
```

**Benefits**:
- ✅ Nginx never crashes (no upstream dependencies)
- ✅ Traefik handles service discovery automatically
- ✅ Easy to add/remove services without touching Nginx
- ✅ Traefik has built-in health checks and retry logic

---

### Pattern 2: Optional Upstream (If you must use Nginx proxy)

**Use Case**: Single-container deployments without Traefik.

```nginx
# Define upstream with resolver (Docker DNS)
upstream qdrant_backend {
    server qdrant:6333 max_fails=3 fail_timeout=30s;
    # Nginx will mark as down if unreachable, not crash
}

server {
    listen 8080;
    
    location /api/qdrant/ {
        # Graceful fallback if upstream down
        proxy_pass http://qdrant_backend/;
        proxy_next_upstream error timeout http_502 http_503;
        
        # Return JSON error instead of HTML
        error_page 502 503 504 = @qdrant_unavailable;
    }
    
    location @qdrant_unavailable {
        default_type application/json;
        return 503 '{"error": "Qdrant temporarily unavailable"}';
    }
}
```

**Limitation**: Still requires `qdrant` hostname to resolve at startup. Use Pattern 1 instead.

---

## EasyWay Decision

**Chosen**: **Pattern 1** (Traefik handles all proxying)

**Rationale**:
1. Frontend Nginx = Static files only (zero dependencies)
2. Traefik = Service mesh (handles Qdrant, N8N, etc.)
3. Antifragile: Frontend never crashes due to backend issues

**Implementation**:
- `apps/portal-frontend/nginx.conf`: No upstream proxies
- `docker-compose.prod.yml`: Traefik routes for all services

---

## Testing Antifragility

```bash
# 1. Stop Qdrant
docker stop qdrant

# 2. Verify frontend still works
curl http://localhost:8080/  # ✅ Should return 200

# 3. Verify Traefik returns graceful error
curl http://localhost/api/qdrant/  # ✅ Should return 503 (not crash)
```

---

## References

- [Nginx Upstream Docs](https://nginx.org/en/docs/http/ngx_http_upstream_module.html)
- [Traefik Service Discovery](https://doc.traefik.io/traefik/providers/docker/)
- EasyWay Architecture: `docs/decisions.md`
