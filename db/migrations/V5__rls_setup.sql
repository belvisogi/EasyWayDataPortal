/* V5 — Row-Level Security (RLS) setup
   NOTE: Requires application to set SESSION_CONTEXT('tenant_id') = <current_tenant>
   Example per-connection:
     EXEC sp_set_session_context @key = N'tenant_id', @value = @currentTenant;
*/
GO

/* Inline table-valued function used as predicate */
CREATE OR ALTER FUNCTION PORTAL.fn_rls_tenant_filter(@tenant_id NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
  SELECT 1 AS fn_result
  WHERE (
    @tenant_id = CAST(SESSION_CONTEXT(N'tenant_id') AS NVARCHAR(50))
    OR IS_MEMBER(N'db_owner') = 1
  )
);
GO

/* SECURITY POLICY on USERS (disabled by default; enable after app sets session context) */
IF NOT EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'RLS_TENANT_POLICY_USERS')
BEGIN
  CREATE SECURITY POLICY PORTAL.RLS_TENANT_POLICY_USERS
  ADD FILTER PREDICATE PORTAL.fn_rls_tenant_filter(tenant_id) ON PORTAL.USERS
  WITH (STATE = OFF);
END;
GO

/* To enable RLS in environment: */
/* ALTER SECURITY POLICY PORTAL.RLS_TENANT_POLICY_USERS WITH (STATE = ON); */

