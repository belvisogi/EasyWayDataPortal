-- users_deactive.sql
UPDATE PORTAL.USERS
SET is_active = 0,
    updated_at = SYSUTCDATETIME()
WHERE user_id = @user_id AND tenant_id = @tenant_id;
