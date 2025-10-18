UPDATE PORTAL.USERS
SET email = @email,
    display_name = @display_name,
    profile_id = @profile_id,
    is_active = @is_active,
    updated_at = SYSUTCDATETIME()
WHERE user_id = @user_id AND tenant_id = @tenant_id;

SELECT * FROM PORTAL.USERS WHERE user_id = @user_id AND tenant_id = @tenant_id;
