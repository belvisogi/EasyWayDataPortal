/* V8 — Extended properties (descriptions/PII flags) */

/* Example: USERS table */
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Anagrafica utenti multi-tenant',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='USERS';

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Codice utente NDG (CDI...)',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='USERS', @level2type=N'COLUMN',@level2name='user_id';

EXEC sys.sp_addextendedproperty @name=N'PII', @value=N'true',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='USERS', @level2type=N'COLUMN',@level2name='email';

/* Example: TENANT table */
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Anagrafica clienti/tenant',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='TENANT';

