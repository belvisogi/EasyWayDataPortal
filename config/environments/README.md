# EasyWay Environment RBAC Setup

According to the **EasyWay Agentic Architecture Enterprise Standard** (Section 10.1 RBAC-A), an agent must not possess permissions outside of its designated execution scope.

This means we must abandon the monolithic `.env.local` anti-pattern in favor of **Role-Based Environment Segregation**.

## Server Deployment Instruction (OS-Level RBAC)

When deploying these agents on a Server (e.g., Linux/Windows VMs), you must enforce file-level permissions to ensure only the designated service accounts can read their respective `.env` files.

**The Golden Rule:** The human is the final gatekeeper. The server itself cannot execute the L1 `.env.executor` token without explicit human interaction or an approved CI/CD trigger. 

### Recommended Setup (Linux Example)

1. **Copy Samples:** Copy the `.sample` files from this directory to a secure location outside the web root or application directory (e.g., `/etc/easyway/`).
2. **Assign Tokens:** Generate strict, scoped Azure DevOps Personal Access Tokens (PATs) as described in the headers of each file.
3. **Lockdown Permissions:**
   ```bash
   # Create distinct service accounts
   useradd -s /sbin/nologin -M easyway_discovery
   useradd -s /sbin/nologin -M easyway_planner
   useradd -s /sbin/nologin -M easyway_executor
   
   # Set ownership
   chown easyway_discovery:easyway_discovery /etc/easyway/.env.discovery
   chown easyway_planner:easyway_planner /etc/easyway/.env.planner
   chown easyway_executor:easyway_executor /etc/easyway/.env.executor
   
   # 400 Permissions: Only the owner service account can read the file
   chmod 400 /etc/easyway/.env.*
   ```

By doing this, even if the `agent_discovery` is compromised (Cognitive Risk), the OS prevents it from reading `/etc/easyway/.env.executor`, thereby eliminating the possibility of it writing to Azure DevOps.
