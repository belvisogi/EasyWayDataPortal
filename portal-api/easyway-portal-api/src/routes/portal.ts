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
  <html><head><meta charset=\"utf-8\"><title>EasyWay Portal</title>
  <style> .banner{border:1px dashed #0b5fff;background:#f8fbff;padding:12px 16px;border-radius:8px;margin:12px 0} </style>
  </head>
  <body style=\"font-family: Arial, sans-serif; padding: 16px;\">
    <h1>EasyWay Portal</h1>
    <div class=\"banner\"> 
      <strong>Preview — stiamo costruendo un portale per tutti.</strong><br/>
      Inclusività digitale: dar voce ai tuoi dati. 
      <div style=\"margin-top:6px\">
        <a href=\"/Wiki/EasyWayData.wiki/value-proposition.md\">Visione & Value Proposition</a> · 
        <a href=\"/Wiki/EasyWayData.wiki/roadmap.md\">Roadmap</a>
      </div>
    </div>
    <ul>
      <li><a href="./home">Home EasyWay (static)</a></li>
      <li><a href="./palette">Palette EasyWay (static)</a></li>
      <li><a href="./logo.png">Logo (static)</a></li>
      <li><a href="./app">Login & Registrazione (demo MSAL)</a></li>
      <li><a href="./tools/db-diagram">DB Diagram Viewer (PORTAL)</a></li>
      <li><a href="./tenant/${defTenant}">Portal dinamico (branding) - tenant: ${defTenant}</a></li>
      <li><a href="/Wiki/EasyWayData.wiki/value-proposition.md">Visione & Value Proposition</a></li>
      <li><a href="/Wiki/EasyWayData.wiki/roadmap.md">Roadmap</a></li>
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
          .banner { border:1px dashed var(--primary); background:#f8fbff; padding:12px 16px; border-radius:8px; margin-bottom:16px; }
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
          <div class="banner">
            <strong>Preview - Stiamo costruendo EasyWay, la gestione dati per tutti.</strong>
            <div style="margin-top:4px;">Inclusività digitale: dar voce ai tuoi dati.</div>
            <div style="margin-top:4px;">
              Questa è una preview tecnica agent‑first. Le fondamenta (sicurezza, WhatIf, gates) sono già operative; nei prossimi mesi apriremo le funzionalità per tutti.
            </div>
          </div>
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
              <li><a href="/Wiki/EasyWayData.wiki/value-proposition.md">Visione & Value Proposition</a></li>
              <li><a href="/Wiki/EasyWayData.wiki/roadmap.md">Roadmap</a></li>
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
    res.status(500).type('text/html').send(`<!doctype html><html><body><h1>Portal error</h1><pre>${(err?.message || String(err))}</pre></body></html>`);
  }
});



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
    tenant: (process.env.AUTH_TENANT_ID || (process.env.AUTH_ISSUER || '').split('/')[3] || "common"),
    apiBase: process.env.PORT ? `${_req.protocol}://${_req.get('host')}` : (process.env.API_BASE || ''),
    scopes: (process.env.AUTH_SCOPES || 'api://default/.default').split(',').map(s => s.trim())
  };
  res.json(cfg);
});

router.get("/tools/db-diagram", (_req, res) => {
  res.type("html").send(`<!doctype html>
  <html lang="it">
  <head>
    <meta charset="utf-8" />
    <title>DB Diagram Viewer (PORTAL)</title>
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <style>
      body { margin:0; font-family: Arial, sans-serif; color:#222; }
      header { padding:14px 16px; border-bottom:1px solid #e6e6e6; background:#fff; display:flex; justify-content:space-between; gap:12px; align-items:flex-start; flex-wrap:wrap; }
      .muted { color:#666; font-size:13px; }
      .wrap { display:flex; height: calc(100vh - 72px); }
      .sidebar { width: 380px; border-right:1px solid #e6e6e6; padding:12px 12px; overflow:auto; background:#fafafa; }
      .main { flex:1; position:relative; }
      canvas { width:100%; height:100%; display:block; background:#fff; }
      .panel { margin-bottom:14px; padding:10px; background:#fff; border:1px solid #e6e6e6; border-radius:6px; }
      .row { display:flex; gap:8px; align-items:center; flex-wrap:wrap; }
      button { padding:6px 10px; border:1px solid #ccc; border-radius:6px; background:#fff; cursor:pointer; }
      button:hover { background:#f2f2f2; }
      button.primary { background:#0b5fff; color:#fff; border-color:#0b5fff; }
      button.primary:hover { background:#0949c9; }
      label { font-size:13px; }
      input[type="checkbox"] { transform: translateY(1px); }
      .list { margin:6px 0 0 0; padding-left:18px; }
      .pill { display:inline-block; padding:2px 8px; border-radius:12px; font-size:12px; border:1px solid #ddd; background:#f7f7f7; margin-left:6px; }
      .k-explicit { border-color:#2b2; color:#173; background:#eef9ee; }
      .k-inferred { border-color:#99a; color:#334; background:#f1f2ff; }
      .table-name { font-weight:600; }
      .code { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; font-size:12px; }
      pre.code { white-space:pre-wrap; background:#f7f7f7; padding:8px; border-radius:6px; border:1px solid #e6e6e6; overflow:auto; }
    </style>
  </head>
  <body>
    <header>
      <div>
        <div style="font-size:18px; font-weight:700;">DB Diagram Viewer (PORTAL)</div>
        <div class="muted">Contesto: viewer interno enterprise. Fonte canonica: JSON pubblicato dall'API (rigenerabile da Flyway).</div>
        <div class="muted">Endpoint: <span class="code">GET /api/db/diagram?schema=PORTAL</span></div>
      </div>
      <div class="row">
        <div id="authStatus" class="muted">non autenticato</div>
        <button id="btnLogin" class="primary">Login</button>
        <button id="btnLogout" disabled>Logout</button>
      </div>
    </header>

    <div class="wrap">
      <aside class="sidebar">
        <div class="panel">
          <div class="row">
            <button id="btnLoad" class="primary" disabled>Carica da API</button>
            <button id="btnRelayout" disabled>Re-layout</button>
            <button id="btnReset" disabled>Reset view</button>
          </div>
          <div class="row" style="margin-top:8px;">
            <label><input id="toggleInferred" type="checkbox" checked /> mostra relazioni inferite</label>
          </div>
          <div class="row" style="margin-top:10px;">
            <label for="fileInput" class="muted">Fallback: carica JSON locale</label>
            <input id="fileInput" type="file" accept=".json" />
          </div>
          <div class="row" style="margin-top:10px;">
            <label for="tokenInput" class="muted">Fallback: incolla Bearer token (dev)</label>
            <input id="tokenInput" type="text" placeholder="eyJhbGciOi..." style="width: 100%;" />
            <button id="btnUseToken">Usa token</button>
          </div>
          <div id="loadMsg" class="muted" style="margin-top:8px;"></div>
        </div>

        <div class="panel">
          <div><strong>Selezione</strong></div>
          <div id="selection" class="muted" style="margin-top:6px;">Nessuna tabella selezionata.</div>
          <div id="selectionCols" class="muted" style="margin-top:8px;"></div>
        </div>

        <div class="panel">
          <div class="row" style="justify-content:space-between;">
            <strong>Tabelle</strong>
            <span class="muted"><span id="tableCount">0</span></span>
          </div>
          <ul id="tableList" class="list"></ul>
        </div>

        <div class="panel">
          <div><strong>Legenda</strong></div>
          <div class="muted" style="margin-top:6px;">
            <div><span class="pill k-explicit">explicit</span> vincolo FK nel DDL</div>
            <div style="margin-top:4px;"><span class="pill k-inferred">inferred</span> relazione da convenzione (es. tenant_id)</div>
          </div>
        </div>
      </aside>

      <main class="main">
        <canvas id="c"></canvas>
      </main>
    </div>

    <script src="https://alcdn.msauth.net/browser/2.38.3/js/msal-browser.min.js" crossorigin="anonymous"></script>
    <script>
      const basePath = ${JSON.stringify(basePath)};
      const cfgUrl = location.origin + basePath + '/app/config';
      const canvas = document.getElementById('c');
      const ctx = canvas.getContext('2d');
      const loadMsg = document.getElementById('loadMsg');
      const tokenInput = document.getElementById('tokenInput');

      let msalApp, account, apiBase = location.origin;
      let manualToken = '';
      let model = null;
      let nodes = [];
      let edges = [];
      let showInferred = true;
      let selectedNodeId = null;
      let panX = 0, panY = 0, zoom = 1;
      let isPanning = false;
      let panStart = null;

      function setMsg(s){ loadMsg.textContent = s || ''; }
      function setAuth(ok){
        document.getElementById('authStatus').textContent = ok ? ('autenticato: ' + (account?.username || '')) : 'non autenticato';
        document.getElementById('btnLogout').disabled = !ok;
        document.getElementById('btnLoad').disabled = !ok;
        document.getElementById('btnRelayout').disabled = !ok;
        document.getElementById('btnReset').disabled = !ok;
      }

      async function loadCfg() {
        const r = await fetch(cfgUrl);
        if (!r.ok) throw new Error('Config non disponibile');
        const cfg = await r.json();
        apiBase = cfg.apiBase || location.origin;
        if (!window.msal) {
          throw new Error('MSAL non disponibile (offline o CDN bloccata). Usa il token manuale o abilita la rete.');
        }
        const msalConfig = {
          auth: {
            clientId: cfg.clientId,
            authority: 'https://login.microsoftonline.com/' + cfg.tenant,
            redirectUri: window.location.origin + basePath + '/tools/db-diagram'
          },
          cache: { cacheLocation: 'sessionStorage' }
        };
        msalApp = new msal.PublicClientApplication(msalConfig);
        const accs = msalApp.getAllAccounts();
        if (accs.length > 0) { account = accs[0]; setAuth(true); }
      }

      async function login() {
        try {
          const resp = await msalApp.loginPopup({ scopes: ['api://default/.default','User.Read'] });
          account = resp.account; setAuth(true);
        } catch(e) { alert('Login fallito: ' + e.message); }
      }
      async function logout(){ try { await msalApp.logoutPopup(); account=null; setAuth(false);} catch(e){} }
      async function getToken(){
        if (manualToken) return manualToken;
        if (!account) throw new Error('no account');
        const req = { account, scopes: ['api://default/.default'] };
        try { const r = await msalApp.acquireTokenSilent(req); return r.accessToken; }
        catch { const r = await msalApp.acquireTokenPopup(req); return r.accessToken; }
      }

      function resizeCanvas() {
        const r = canvas.getBoundingClientRect();
        const dpr = window.devicePixelRatio || 1;
        canvas.width = Math.floor(r.width * dpr);
        canvas.height = Math.floor(r.height * dpr);
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        draw();
      }
      window.addEventListener('resize', resizeCanvas);

      function loadModel(m) {
        model = m;
        const colMap = new Map();
        (m.columns || []).forEach(t => colMap.set(t.table, t.columns || []));
        nodes = (m.nodes || []).map((n, i) => {
          const id = n.id || (n.schema + '.' + n.table);
          return { id, label: id, cols: colMap.get(id) || [], x: 80 + (i % 4) * 220 + Math.random() * 30, y: 80 + Math.floor(i / 4) * 160 + Math.random() * 30, vx: 0, vy: 0 };
        });
        const nodeIds = new Set(nodes.map(n => n.id));
        edges = (m.edges || []).filter(e => nodeIds.has(e.from) && nodeIds.has(e.to)).map(e => ({ from: e.from, to: e.to, kind: e.kind || 'inferred' }));
        selectedNodeId = null; panX = 0; panY = 0; zoom = 1;
        updateSidebar(); relayout();
      }

      function updateSidebar() {
        document.getElementById('tableCount').textContent = String(nodes.length);
        const list = document.getElementById('tableList');
        list.innerHTML = '';
        nodes.slice().sort((a,b) => a.label.localeCompare(b.label)).forEach(n => {
          const li = document.createElement('li');
          li.style.cursor = 'pointer';
          li.innerHTML = '<span class="table-name">' + escapeHtml(n.label) + '</span>';
          li.onclick = () => { selectedNodeId = n.id; centerOn(n); updateSelection(); draw(); };
          list.appendChild(li);
        });
        updateSelection();
      }

      function updateSelection() {
        const sel = nodes.find(n => n.id === selectedNodeId);
        const el = document.getElementById('selection');
        const colsEl = document.getElementById('selectionCols');
        if (!sel) { el.textContent = 'Nessuna tabella selezionata.'; colsEl.textContent = ''; return; }
        el.innerHTML = '<div class="table-name">' + escapeHtml(sel.label) + '</div>';
        const cols = (sel.cols || []).map(c => '- ' + (c.name || '') + (c.sql_type ? (' (' + c.sql_type + ')') : ''));
        colsEl.innerHTML = '<div class="muted" style="margin-top:6px;"><strong>Colonne</strong></div>' + '<pre class="code">' + escapeHtml(cols.join('\\n')) + '</pre>';
      }

      function relayout() {
        const byId = new Map(nodes.map(n => [n.id, n]));
        const visibleEdges = edges.filter(e => showInferred || e.kind !== 'inferred');
        const iterations = 420, repulsion = 22000, spring = 0.010, springLen = 180, damping = 0.82;
        for (let it = 0; it < iterations; it++) {
          for (let i = 0; i < nodes.length; i++) {
            for (let j = i + 1; j < nodes.length; j++) {
              const a = nodes[i], b = nodes[j];
              let dx = a.x - b.x, dy = a.y - b.y;
              let dist2 = dx*dx + dy*dy + 0.01;
              const f = repulsion / dist2;
              const dist = Math.sqrt(dist2);
              const fx = (dx / dist) * f, fy = (dy / dist) * f;
              a.vx += fx; a.vy += fy; b.vx -= fx; b.vy -= fy;
            }
          }
          for (const e of visibleEdges) {
            const a = byId.get(e.from), b = byId.get(e.to);
            if (!a || !b) continue;
            let dx = b.x - a.x, dy = b.y - a.y;
            let dist = Math.sqrt(dx*dx + dy*dy) + 0.001;
            const force = spring * (dist - springLen);
            const fx = (dx / dist) * force, fy = (dy / dist) * force;
            a.vx += fx; a.vy += fy; b.vx -= fx; b.vy -= fy;
          }
          for (const n of nodes) { n.vx *= damping; n.vy *= damping; n.x += n.vx * 0.03; n.y += n.vy * 0.03; }
        }
        draw();
      }

      function worldToScreen(x, y) { return { x: (x + panX) * zoom, y: (y + panY) * zoom }; }
      function screenToWorld(x, y) { return { x: x / zoom - panX, y: y / zoom - panY }; }
      function nodeBox(n) { const w = Math.max(140, 10 + n.label.length * 7), h = 44; return { x: n.x - w/2, y: n.y - h/2, w, h }; }
      function roundRect(ctx, x, y, w, h, r) {
        const rr = Math.min(r, w/2, h/2);
        ctx.beginPath();
        ctx.moveTo(x + rr, y);
        ctx.arcTo(x + w, y, x + w, y + h, rr);
        ctx.arcTo(x + w, y + h, x, y + h, rr);
        ctx.arcTo(x, y + h, x, y, rr);
        ctx.arcTo(x, y, x + w, y, rr);
        ctx.closePath();
      }
      function draw() {
        const w = canvas.getBoundingClientRect().width;
        const h = canvas.getBoundingClientRect().height;
        ctx.clearRect(0, 0, w, h);
        if (!model) { ctx.fillStyle = '#666'; ctx.font = '14px Arial'; ctx.fillText('Login e clicca \"Carica da API\".', 16, 24); return; }
        const byId = new Map(nodes.map(n => [n.id, n]));
        const visibleEdges = edges.filter(e => showInferred || e.kind !== 'inferred');
        for (const e of visibleEdges) {
          const a = byId.get(e.from), b = byId.get(e.to);
          if (!a || !b) continue;
          const A = worldToScreen(a.x, a.y), B = worldToScreen(b.x, b.y);
          ctx.beginPath();
          ctx.lineWidth = (e.kind === 'explicit') ? 1.6 : 1.0;
          ctx.strokeStyle = (e.kind === 'explicit') ? '#2b7' : '#778';
          ctx.setLineDash((e.kind === 'explicit') ? [] : [6, 4]);
          ctx.moveTo(A.x, A.y); ctx.lineTo(B.x, B.y); ctx.stroke();
        }
        ctx.setLineDash([]);
        for (const n of nodes) {
          const box = nodeBox(n);
          const tl = worldToScreen(box.x, box.y);
          const ww = box.w * zoom, hh = box.h * zoom;
          const isSel = (n.id === selectedNodeId);
          ctx.fillStyle = isSel ? '#e8f4ff' : '#fff';
          ctx.strokeStyle = isSel ? '#2680d9' : '#cfcfcf';
          ctx.lineWidth = isSel ? 2 : 1;
          roundRect(ctx, tl.x, tl.y, ww, hh, 8);
          ctx.fill(); ctx.stroke();
          ctx.fillStyle = '#222';
          ctx.font = (Math.max(11, 12 * zoom)) + 'px Arial';
          ctx.textBaseline = 'middle';
          ctx.fillText(n.label, tl.x + 10, tl.y + hh/2);
        }
      }
      function centerOn(n) {
        const w = canvas.getBoundingClientRect().width;
        const h = canvas.getBoundingClientRect().height;
        panX = (w / (2 * zoom)) - n.x;
        panY = (h / (2 * zoom)) - n.y;
      }
      function resetView(){ panX = 0; panY = 0; zoom = 1; draw(); }
      function escapeHtml(s) { if (!s && s !== '') return ''; return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

      async function loadFromApi() {
        setMsg('Caricamento da API...');
        try {
          const token = await getToken();
          const r = await fetch(apiBase + '/api/db/diagram?schema=PORTAL', { headers: { 'Authorization': 'Bearer ' + token } });
          if (!r.ok) throw new Error('HTTP ' + r.status);
          const j = await r.json();
          loadModel(j);
          setMsg('OK: ' + (j.nodes?.length || 0) + ' tabelle');
        } catch (e) {
          setMsg('Errore: ' + (e.message || e));
        }
      }

      canvas.addEventListener('mousedown', (ev) => { isPanning = true; panStart = { x: ev.clientX, y: ev.clientY, panX, panY }; });
      window.addEventListener('mouseup', () => { isPanning = false; panStart = null; });
      window.addEventListener('mousemove', (ev) => {
        if (!isPanning || !panStart) return;
        const dx = (ev.clientX - panStart.x) / zoom;
        const dy = (ev.clientY - panStart.y) / zoom;
        panX = panStart.panX + dx;
        panY = panStart.panY + dy;
        draw();
      });
      canvas.addEventListener('click', (ev) => {
        if (!model) return;
        const rect = canvas.getBoundingClientRect();
        const x = ev.clientX - rect.left;
        const y = ev.clientY - rect.top;
        const p = screenToWorld(x, y);
        for (const n of nodes) {
          const b = nodeBox(n);
          if (p.x >= b.x && p.x <= (b.x + b.w) && p.y >= b.y && p.y <= (b.y + b.h)) { selectedNodeId = n.id; updateSelection(); draw(); return; }
        }
        selectedNodeId = null; updateSelection(); draw();
      });
      canvas.addEventListener('wheel', (ev) => {
        ev.preventDefault();
        const rect = canvas.getBoundingClientRect();
        const mx = ev.clientX - rect.left;
        const my = ev.clientY - rect.top;
        const before = screenToWorld(mx, my);
        const factor = (ev.deltaY > 0) ? 0.92 : 1.08;
        zoom = Math.max(0.45, Math.min(2.8, zoom * factor));
        const after = screenToWorld(mx, my);
        panX += (after.x - before.x);
        panY += (after.y - before.y);
        draw();
      }, { passive: false });

      document.getElementById('btnLogin').onclick = login;
      document.getElementById('btnLogout').onclick = logout;
      document.getElementById('btnLoad').onclick = loadFromApi;
      document.getElementById('btnRelayout').onclick = relayout;
      document.getElementById('btnReset').onclick = resetView;
      document.getElementById('btnUseToken').onclick = () => {
        manualToken = (tokenInput.value || '').trim();
        if (manualToken) {
          setMsg('Token manuale impostato. Ora puoi cliccare "Carica da API".');
          setAuth(true);
        } else {
          setMsg('Token vuoto.');
        }
      };
      document.getElementById('toggleInferred').addEventListener('change', (ev) => { showInferred = !!ev.target.checked; draw(); });
      document.getElementById('fileInput').addEventListener('change', (ev) => {
        const f = ev.target.files[0];
        if (!f) return;
        const reader = new FileReader();
        reader.onload = (e) => {
          try { loadModel(JSON.parse(e.target.result)); setMsg('Caricato da file locale.'); }
          catch (err) { setMsg('JSON non valido: ' + err.message); }
        };
        reader.readAsText(f);
      });

      resizeCanvas();
      loadCfg().then(() => setAuth(!!account)).catch(e => setMsg('Errore config: ' + e.message));
      setAuth(false);
      draw();
    </script>
  </body>
  </html>`);
});

export default router;

