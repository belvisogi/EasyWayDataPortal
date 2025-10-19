// easyway-portal-api/src/routes/portal.ts
import { Router } from "express";
import path from "path";
import fs from "fs";
import { loadBrandingConfig } from "../config/brandingLoader";

const router = Router();

// Calcola la root del repo a runtime (dist -> api -> EasyWay-DataPortal -> repo root)
const repoRoot = path.resolve(__dirname, "../../../");
const basePath = process.env.PORTAL_BASE_PATH || '/portal';

function sendIfExists(res: any, p: string, contentType?: string) {
  if (!fs.existsSync(p)) {
    return res.status(404).send("Not found");
  }
  if (contentType) res.type(contentType);
  return res.sendFile(p);
}

router.get(["/", ""], (_req, res) => {
  const defTenant = process.env.DEFAULT_TENANT_ID || 'tenant01';
  res.type("html").send(`<!doctype html>
  <html><head><meta charset="utf-8"><title>EasyWay Portal</title></head>
  <body style="font-family: Arial, sans-serif; padding: 16px;">
    <h1>EasyWay Portal</h1>
    <ul>
      <li><a href="./home">Home EasyWay (static)</a></li>
      <li><a href="./palette">Palette EasyWay (static)</a></li>
      <li><a href="./logo.png">Logo (static)</a></li>
      <li><a href="./app">Login & Registrazione (demo MSAL)</a></li>
      <li><a href="./tenant/${defTenant}">Portal dinamico (branding) — tenant: ${defTenant}</a></li>
      <li><a href="/api/docs">API Docs</a></li>
    </ul>
  </body></html>`);
});

router.get("/home", (_req, res) => {
  const p = path.resolve(repoRoot, "home_easyway.html");
  return sendIfExists(res, p, "text/html");
});

router.get("/palette", (_req, res) => {
  const p = path.resolve(repoRoot, "palette_EasyWay.html");
  return sendIfExists(res, p, "text/html");
});

router.get("/logo.png", (_req, res) => {
  const p = path.resolve(repoRoot, "logo.png");
  return sendIfExists(res, p, "image/png");
});

router.get("/tenant/:tenantId", async (req, res) => {
  try {
    const tenantId = req.params.tenantId || process.env.DEFAULT_TENANT_ID || 'tenant01';
    const cfg = await loadBrandingConfig(tenantId);
    const primary = cfg.branding?.primary_color || '#0b5fff';
    const secondary = cfg.branding?.secondary_color || '#ffd200';
    const bg = cfg.branding?.background_image || '';
    const logo = cfg.branding?.logo || '/portal/logo.png';
    const font = cfg.branding?.font || 'Inter, Arial, sans-serif';
    const title = cfg.labels?.portal_title || 'EasyWay Data Portal';
    const welcome = cfg.labels?.welcome_message || `Benvenuto su EasyWay — ${tenantId}`;

    const cssBg = bg ? `background-image:url('${bg}');background-size:cover;background-position:center;` : '';

    const html = `<!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>${title}</title>
        <style>
          :root { --primary: ${primary}; --secondary: ${secondary}; --font: ${font}; }
          body { margin:0; font-family: var(--font); ${cssBg} }
          header { display:flex; align-items:center; gap:16px; padding:16px; background: linear-gradient(90deg, var(--primary), var(--secondary)); color:#000; }
          header img { height: 48px; }
          main { padding:24px; background: rgba(255,255,255,0.92); min-height: calc(100vh - 96px); }
          .badge { display:inline-block; padding:4px 8px; border-radius:12px; background: var(--secondary); color:#000; font-weight:600; }
          .links a { display:inline-block; margin-right:16px; color: var(--primary); text-decoration:none; font-weight:600; }
          .card { border:1px solid #ddd; border-radius:8px; padding:16px; margin:8px 0; background:#fff; }
        </style>
      </head>
      <body>
        <header>
          <img src="${logo}" alt="logo" onerror="this.src='${basePath}/logo.png'" />
          <div>
            <div class="badge">Tenant: ${tenantId}</div>
            <h1 style="margin:4px 0 0">${title}</h1>
          </div>
        </header>
        <main>
          <p>${welcome}</p>
          <div class="links">
            <a href="/api/docs">API Docs</a>
            <a href="${basePath}/home">Home (static)</a>
            <a href="${basePath}/palette">Palette (static)</a>
          </div>
          <section class="card">
            <h3>Manifesto & Wiki</h3>
            <ul>
              <li><a href="${basePath}/home">Manifesto visivo</a></li>
              <li><a href="${basePath}/palette">Palette & Branding</a></li>
            </ul>
          </section>
          <section class="card">
            <h3>Endpoint Rapidi</h3>
            <ul>
              <li>GET <code>/api/health</code> (JWT richiesto)</li>
              <li>GET <code>/api/branding</code> (JWT + tenant claim)</li>
              <li>GET/POST <code>/api/users</code> (JWT + tenant claim)</li>
            </ul>
          </section>
        </main>
      </body>
    </html>`;
    res.type('html').send(html);
  } catch (err: any) {
    res.status(500).type('text/html').send(`<!doctype html><html><body><h1>Portal error</h1><pre>${(err?.message||String(err))}</pre></body></html>`);
  }
});

export default router;

/* ---- Simple App (MSAL demo) ---- */
router.get("/app", (_req, res) => {
  res.type("html").send(`<!doctype html>
  <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>EasyWay – Login & Registrazione</title>
      <script src="https://alcdn.msauth.net/browser/2.38.3/js/msal-browser.min.js" integrity="sha384-7F+9GxM0gTLnL5KNs0N6b0rQ1B/9cQeJxqOZi3tHnqvP2bS8wE3hA2Kc4LwW0yS/" crossorigin="anonymous"></script>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 24px; }
        .row { margin: 12px 0; }
        input, button, select { padding: 8px; }
        .card { border: 1px solid #ddd; border-radius: 8px; padding: 16px; margin-bottom: 16px; }
        .ok { color: #0a0; } .err { color: #a00; }
      </style>
    </head>
    <body>
      <h1>Login & Registrazione (demo)</h1>
      <div class="card">
        <div class="row">
          <label>Tenant (business): <input id="tenantId" value="${process.env.DEFAULT_TENANT_ID || 'tenant01'}" /></label>
        </div>
        <div class="row">
          <button id="btnLogin">Login con Microsoft</button>
          <button id="btnLogout" disabled>Logout</button>
        </div>
        <div class="row">
          <small>Stato: <span id="status">non autenticato</span></small>
        </div>
      </div>
      <div class="card">
        <h3>Registrazione Utente</h3>
        <div class="row"><label>Email: <input id="regEmail" placeholder="user@example.com"/></label></div>
        <div class="row"><label>Display name: <input id="regName" placeholder="Nome Cognome"/></label></div>
        <div class="row"><label>Profile ID: <input id="regProfile" value="TENANT_ADMIN"/></label></div>
        <div class="row"><button id="btnRegister" disabled>Registra</button></div>
        <pre id="regOut"></pre>
      </div>
      <div class="card">
        <h3>Lista Utenti (tenant)</h3>
        <div class="row"><button id="btnList" disabled>Lista</button></div>
        <pre id="listOut"></pre>
      </div>
      <script>
        const cfgUrl = location.origin + '${basePath}/app/config';
        let msalApp, account, accessToken;
        let apiBase = location.origin;
        const statusEl = document.getElementById('status');
        const btnLogin = document.getElementById('btnLogin');
        const btnLogout = document.getElementById('btnLogout');
        const btnRegister = document.getElementById('btnRegister');
        const btnList = document.getElementById('btnList');
        const regOut = document.getElementById('regOut');
        const listOut = document.getElementById('listOut');
        const tenantInput = document.getElementById('tenantId');

        async function loadCfg() {
          const r = await fetch(cfgUrl);
          if (!r.ok) throw new Error('Config non disponibile');
          const cfg = await r.json();
          apiBase = cfg.apiBase;
          const msalConfig = {
            auth: {
              clientId: cfg.clientId,
              authority: 'https://login.microsoftonline.com/' + cfg.tenant,
              redirectUri: window.location.origin + '${basePath}/app'
            },
            cache: { cacheLocation: 'sessionStorage' }
          };
          msalApp = new msal.PublicClientApplication(msalConfig);
          const accs = msalApp.getAllAccounts();
          if (accs.length > 0) { account = accs[0]; updateUiAuth(true); }
        }
        function updateUiAuth(ok){
          statusEl.textContent = ok ? ('autenticato: ' + (account?.username || '')) : 'non autenticato';
          btnLogout.disabled = !ok; btnRegister.disabled = !ok; btnList.disabled = !ok;
        }
        async function login() {
          try {
            const resp = await msalApp.loginPopup({ scopes: ['api://default/.default','User.Read'] });
            account = resp.account; updateUiAuth(true);
          } catch(e) { alert('Login fallito: ' + e.message); }
        }
        async function logout(){ try { await msalApp.logoutPopup(); account=null; updateUiAuth(false);} catch(e){}}
        async function getToken(){
          if (!account) throw new Error('no account');
          const req = { account, scopes: ['api://default/.default'] };
          try { const r = await msalApp.acquireTokenSilent(req); return r.accessToken; }
          catch { const r = await msalApp.acquireTokenPopup(req); return r.accessToken; }
        }
        async function register(){
          regOut.textContent='';
          try {
            accessToken = await getToken();
            const body = {
              tenant_name: tenantInput.value || 'Tenant Demo',
              user_email: document.getElementById('regEmail').value,
              display_name: document.getElementById('regName').value,
              profile_id: document.getElementById('regProfile').value,
              ext_attributes: { source:'portal-demo' }
            };
            const r = await fetch(apiBase + '/api/onboarding', { method:'POST', headers:{ 'Content-Type':'application/json', 'Authorization':'Bearer ' + accessToken }, body: JSON.stringify(body) });
            const j = await r.json(); regOut.textContent = JSON.stringify(j,null,2);
          } catch(e){ regOut.textContent = 'Errore: ' + e.message; }
        }
        async function listUsers(){
          listOut.textContent='';
          try {
            accessToken = await getToken();
            const r = await fetch(apiBase + '/api/users', { headers:{ 'Authorization':'Bearer ' + accessToken } });
            const j = await r.json(); listOut.textContent = JSON.stringify(j,null,2);
          } catch(e){ listOut.textContent = 'Errore: ' + e.message; }
        }
        btnLogin.onclick = login; btnLogout.onclick = logout; btnRegister.onclick = register; btnList.onclick = listUsers;
        loadCfg();
      </script>
    </body>
  </html>`);
});

router.get("/app/config", (_req, res) => {
  const cfg = {
    clientId: process.env.AUTH_CLIENT_ID || "YOUR_MSAL_CLIENT_ID",
    tenant: (process.env.AUTH_TENANT_ID || (process.env.AUTH_ISSUER||'').split('/')[3] || "common"),
    apiBase: process.env.PORT ? `${_req.protocol}://${_req.get('host')}` : (process.env.API_BASE || ''),
    scopes: (process.env.AUTH_SCOPES || 'api://default/.default').split(',').map(s => s.trim())
  };
  res.json(cfg);
});
