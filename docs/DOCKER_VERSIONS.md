# Docker Image Version Management

## Current Pinned Versions (Last Updated: 2026-02-07)

| Service | Version | Update Policy | Notes |
|---------|---------|---------------|-------|
| n8n | 1.123.20 | Monthly review | Check releases weekly |
| Traefik | v3.2 | Quarterly | v2.11 EOL'd Feb 1, 2026 ⚠️ |
| Qdrant | v1.12.4 | Monthly | Vector DB - test compatibility |
| ChromaDB | 0.6.3 | Monthly | Alternative vector DB |
| MinIO | bitnami/minio:2026.1.15-debian-12-r0 | Monthly | Using Bitnami (official stopped free Docker Hub Oct 2025) |
| PostgreSQL | 15.10-alpine | Monthly | Security patches important |
| Azure SQL Edge | 2.0.0 | Quarterly | Microsoft release schedule |
| GitLab CE | 17.8.1-ce.0 | Monthly | Match runner version |
| GitLab Runner | v17.8.0 | Monthly | Match GitLab CE version |

## Update Process

1. **Review releases monthly** (first Monday of each month)
2. **Test in dev environment**
   - Pull new images
   - Test compatibility with existing configuration
   - Check for breaking changes in release notes
3. **Update docker-compose files**
   - Update version tags in all affected files
   - Document changes in git commit message
4. **Deploy to staging**
   - Monitor logs for errors
   - Test critical workflows
5. **Deploy to production** (after 48h successful staging)

## Version Pinning Policy

### Rules
- **NEVER use `:latest` in production**
- Pin to specific semantic versions (e.g., `v1.23.2`, not `v1.23` or `1`)
- Update within **30 days** of security releases
- Test compatibility before upgrading

### Why Pin Versions?
- **Predictability**: Rebuilds produce identical containers
- **Security**: Know exactly what code is running
- **Debugging**: Easier to correlate issues with specific versions
- **Compliance**: Auditable software supply chain

## Breaking Changes Log

### 2026-02-07: Traefik v2.11 → v3.2
**CRITICAL UPGRADE** - v2.11 reached End-of-Life Feb 1, 2026

**Breaking Changes:**
- `api.insecure` → `api.dashboard`
- Some middleware names changed
- TLS configuration syntax updated

**Migration Guide:** https://doc.traefik.io/traefik/migration/v2-to-v3/

### 2026-02-07: MinIO Official → Bitnami
MinIO stopped publishing free Docker images to Docker Hub (Oct 2025)

**Changes:**
- Image: `minio/minio:latest` → `bitnami/minio:2026.1.15-debian-12-r0`
- Data path: `/data` → `/bitnami/minio/data`
- Config path: Changed to Bitnami structure

**Alternative:** Can still use official `minio/minio:RELEASE.2026-01-15T18-56-18Z` but no future updates

## Security Advisory Sources

Monitor these sources for security updates:

- **n8n**: https://github.com/n8n-io/n8n/releases
- **Traefik**: https://github.com/traefik/traefik/releases
- **Qdrant**: https://github.com/qdrant/qdrant/releases
- **PostgreSQL**: https://www.postgresql.org/support/security/
- **GitLab**: https://about.gitlab.com/releases/categories/releases/
- **CVE Monitoring**: https://nvd.nist.gov/

## Rollback Procedure

If an upgrade causes issues:

```bash
# 1. Checkout previous docker-compose file
git checkout HEAD~1 -- docker-compose.prod.yml

# 2. Pull old image version (if still available)
docker pull n8nio/n8n:1.22.0

# 3. Recreate containers
docker-compose -f docker-compose.prod.yml up -d --force-recreate

# 4. Verify services are healthy
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f --tail=100
```

## Version Upgrade Checklist

Before upgrading any service:

- [ ] Read release notes for breaking changes
- [ ] Backup all volumes (SQL, Qdrant, PostgreSQL, MinIO)
- [ ] Test in dev environment first
- [ ] Schedule maintenance window
- [ ] Notify stakeholders
- [ ] Have rollback plan ready
- [ ] Monitor logs for 24h after upgrade

## Contact

For questions about version management:
- Review this document
- Check release notes
- Consult team lead before major version upgrades
