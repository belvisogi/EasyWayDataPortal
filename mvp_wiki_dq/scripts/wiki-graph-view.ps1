param(
  [string]$WikiPath = "wiki",
  [string]$OutHtml = "out/graph-view.html",
  [string]$OutGraphJson = "out/graph-view.json",
  [switch]$Open
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-ParentDir([string]$path) {
  $dir = Split-Path -Parent $path
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

Ensure-ParentDir $OutHtml
Ensure-ParentDir $OutGraphJson

$graphReport = (pwsh -NoProfile -File scripts/wiki-orphans.ps1 -WikiPath $WikiPath -OutJson $OutGraphJson -OutMd "wiki/orphans.md" -OutDot "out/graph.dot") | ConvertFrom-Json
if ($null -eq $graphReport.graph -or $null -eq $graphReport.graph.nodes -or $null -eq $graphReport.graph.links) {
  throw "wiki-orphans.ps1 did not emit graph.nodes/graph.links. OutJson=$OutGraphJson"
}

$graphJson = ($graphReport.graph | ConvertTo-Json -Depth 8)
$wikiRoot = (Resolve-Path -LiteralPath $WikiPath).Path
$repoRoot = (Resolve-Path -LiteralPath ".").Path
$wikiRootRel = [IO.Path]::GetRelativePath($repoRoot, $wikiRoot).Replace([char]92,'/')

$html = @"
<!doctype html>
<html lang="it">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Wiki Graph View (MVP)</title>
  <style>
    :root { --bg:#0b1020; --panel:#111a33; --fg:#e8eefc; --muted:#9fb0da; --accent:#7aa2ff; --node:#cfd8ff; --orphan:#ff6b6b; --link:rgba(158,173,214,.20); }
    html,body { height:100%; margin:0; background:var(--bg); color:var(--fg); font:14px/1.35 system-ui,Segoe UI,Roboto,Arial,sans-serif; }
    #wrap { display:grid; grid-template-columns: 360px 1fr; height:100%; }
    #left { background:var(--panel); border-right:1px solid rgba(255,255,255,.08); padding:14px 14px 10px; overflow:auto; }
    #title { font-size:16px; font-weight:700; margin:0 0 6px; }
    #sub { color:var(--muted); margin:0 0 12px; }
    .row { display:flex; gap:8px; align-items:center; margin:10px 0; }
    input[type="text"] { width:100%; padding:8px 10px; border-radius:10px; border:1px solid rgba(255,255,255,.12); background:rgba(0,0,0,.18); color:var(--fg); outline:none; }
    input[type="range"] { width:100%; }
    .kv { display:grid; grid-template-columns: 120px 1fr; gap:6px 10px; margin-top:12px; }
    .k { color:var(--muted); }
    .v { word-break:break-word; }
    a { color: var(--accent); text-decoration: none; }
    a:hover { text-decoration: underline; }
    .hint { color:var(--muted); font-size:12px; margin-top:12px; }
    button { padding:8px 10px; border-radius:10px; border:1px solid rgba(255,255,255,.12); background:rgba(0,0,0,.18); color:var(--fg); cursor:pointer; }
    button:hover { border-color: rgba(122,162,255,.45); }
    #canvas { width:100%; height:100%; display:block; }
    #right { position:relative; }
    #hud { position:absolute; left:14px; top:14px; background:rgba(0,0,0,.35); border:1px solid rgba(255,255,255,.10); padding:8px 10px; border-radius:10px; color:var(--muted); font-size:12px; pointer-events:none; }
  </style>
</head>
<body>
  <div id="wrap">
    <aside id="left">
      <p id="title">Wiki Graph View (MVP)</p>
      <p id="sub">Grafo link Markdown (offline, senza Obsidian). Drag & zoom.</p>

      <div class="row">
        <input id="q" type="text" placeholder="Cerca (path contiene...)">
      </div>
      <div class="row">
        <label style="min-width:120px;color:var(--muted)">Min degree</label>
        <input id="minDeg" type="range" min="0" max="20" value="0">
      </div>
      <div class="row">
        <button id="replay" type="button">Replay animazione</button>
      </div>

      <div class="kv">
        <div class="k">WikiPath</div><div class="v"><code id="wpath"></code></div>
        <div class="k">Nodes</div><div class="v" id="ncount"></div>
        <div class="k">Links</div><div class="v" id="lcount"></div>
      </div>

      <hr style="border:0;border-top:1px solid rgba(255,255,255,.10); margin:14px 0;">

      <div class="kv">
        <div class="k">Selezione</div><div class="v" id="selPath">-</div>
        <div class="k">Degree</div><div class="v" id="selDeg">-</div>
        <div class="k">Open</div><div class="v" id="selOpen">-</div>
      </div>

      <div class="hint">
        Controlli: trascina nodi; mouse wheel = zoom; drag sfondo = pan; click nodo = dettagli. Hover/click evidenzia vicini.
      </div>
    </aside>

    <main id="right">
      <canvas id="canvas"></canvas>
      <div id="hud"></div>
    </main>
  </div>

  <script>
    const WIKI_ROOT = ${([System.Text.Json.JsonSerializer]::Serialize($wikiRootRel))};
    const GRAPH = ${graphJson};

    const nodes = GRAPH.nodes.map(n => ({
      id: n.id,
      path: n.path,
      inDegree: n.inDegree|0,
      outDegree: n.outDegree|0,
      degree: n.degree|0,
      x: (Math.random() - 0.5) * 400,
      y: (Math.random() - 0.5) * 400,
      vx: 0,
      vy: 0
    }));
    const byId = new Map(nodes.map(n => [n.id, n]));
    const links = GRAPH.links
      .map(l => ({ source: byId.get(l.source), target: byId.get(l.target) }))
      .filter(l => l.source && l.target);
    const neighbors = new Map();
    for (const n of nodes) neighbors.set(n.id, new Set());
    for (const l of links) {
      neighbors.get(l.source.id).add(l.target.id);
      neighbors.get(l.target.id).add(l.source.id);
    }

    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d', { alpha: false });
    const hud = document.getElementById('hud');
    const q = document.getElementById('q');
    const minDeg = document.getElementById('minDeg');

    document.getElementById('wpath').textContent = WIKI_ROOT;
    document.getElementById('ncount').textContent = String(nodes.length);
    document.getElementById('lcount').textContent = String(links.length);

    // Timelapse "build-up" (solo animazione layout, non history repo)
    let replayAt = performance.now();
    const replayBtn = document.getElementById('replay');
    replayBtn.addEventListener('click', () => { replayAt = performance.now(); });
    window.addEventListener('keydown', (e) => { if (e.key === 'r' || e.key === 'R') replayAt = performance.now(); });
    function clamp01(v) { return Math.max(0, Math.min(1, v)); }
    function easeOutCubic(t) { t = clamp01(t); return 1 - Math.pow(1 - t, 3); }

    let W = 0, H = 0;
    function resize() {
      const dpr = Math.max(1, window.devicePixelRatio || 1);
      W = canvas.clientWidth; H = canvas.clientHeight;
      canvas.width = Math.floor(W * dpr);
      canvas.height = Math.floor(H * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    window.addEventListener('resize', resize);
    resize();

    let view = { x: W/2, y: H/2, k: 1 };
    let dragging = null;
    let panning = false;
    let panStart = { x:0, y:0, vx:0, vy:0 };
    let selected = null;
    let hovered = null;
    let locked = null;

    function toWorld(px, py) { return { x: (px - view.x) / view.k, y: (py - view.y) / view.k }; }
    function toScreen(wx, wy) { return { x: wx * view.k + view.x, y: wy * view.k + view.y }; }

    function hitNode(px, py) {
      const w = toWorld(px, py);
      const rBase = 3.2;
      let best = null, bestD = Infinity;
      const query = q.value.trim().toLowerCase();
      const minD = parseInt(minDeg.value || '0', 10);
      for (const n of nodes) {
        if (n.degree < minD) continue;
        if (query && !n.path.toLowerCase().includes(query)) continue;
        const dx = n.x - w.x, dy = n.y - w.y;
        const r = rBase + Math.min(10, Math.sqrt(n.degree) * 1.2);
        const d2 = dx*dx + dy*dy;
        if (d2 < r*r && d2 < bestD) { best = n; bestD = d2; }
      }
      return best;
    }

    canvas.addEventListener('mousedown', (e) => {
      const n = hitNode(e.offsetX, e.offsetY);
      if (n) {
        dragging = n;
      } else {
        panning = true;
        panStart = { x: e.offsetX, y: e.offsetY, vx: view.x, vy: view.y };
      }
    });
    window.addEventListener('mouseup', () => { dragging = null; panning = false; });
    canvas.addEventListener('mousemove', (e) => {
      if (dragging) {
        const w = toWorld(e.offsetX, e.offsetY);
        dragging.x = w.x; dragging.y = w.y;
        dragging.vx = 0; dragging.vy = 0;
      } else if (panning) {
        view.x = panStart.vx + (e.offsetX - panStart.x);
        view.y = panStart.vy + (e.offsetY - panStart.y);
      } else {
        const n = hitNode(e.offsetX, e.offsetY);
        hovered = n;
        hud.textContent = n ? n.path : '';
      }
    });
    canvas.addEventListener('click', (e) => {
      const n = hitNode(e.offsetX, e.offsetY);
      if (!n) {
        locked = null;
        selected = null;
      } else {
        locked = (locked && locked.id === n.id) ? null : n;
        selected = locked || n;
      }
      const selPath = document.getElementById('selPath');
      const selDeg = document.getElementById('selDeg');
      const selOpen = document.getElementById('selOpen');
      if (!selected) {
        selPath.textContent = '-';
        selDeg.textContent = '-';
        selOpen.innerHTML = '-';
        return;
      }
      selPath.textContent = selected.path;
      selDeg.textContent = String(selected.degree);
      const href = WIKI_ROOT + '/' + selected.path;
      selOpen.innerHTML = '<a href=\"' + href + '\">apri file</a>';
    });
    canvas.addEventListener('wheel', (e) => {
      e.preventDefault();
      const zoom = Math.exp(-e.deltaY * 0.0015);
      const before = toWorld(e.offsetX, e.offsetY);
      view.k = Math.min(6, Math.max(0.15, view.k * zoom));
      const after = toScreen(before.x, before.y);
      view.x += (e.offsetX - after.x);
      view.y += (e.offsetY - after.y);
    }, { passive: false });

    function step() {
      const query = q.value.trim().toLowerCase();
      const minD = parseInt(minDeg.value || '0', 10);
      const visible = (n) => n.degree >= minD && (!query || n.path.toLowerCase().includes(query));
      const focus = locked || hovered;
      const focusSet = new Set();
      if (focus && neighbors.has(focus.id)) {
        focusSet.add(focus.id);
        for (const nb of neighbors.get(focus.id)) focusSet.add(nb);
      }
      const focusVisible = (n) => !focus || focusSet.size === 0 || focusSet.has(n.id);

      const strengthRepel = 1600;
      const strengthLink = 0.035;
      const centerPull = 0.0018;
      const damping = 0.85;

      const visNodes = nodes.filter(n => visible(n) && focusVisible(n));
      const nLen = visNodes.length;
      for (let i = 0; i < nLen; i++) {
        const a = visNodes[i];
        for (let j = i + 1; j < nLen; j++) {
          const b = visNodes[j];
          let dx = a.x - b.x, dy = a.y - b.y;
          let d2 = dx*dx + dy*dy + 0.01;
          const f = strengthRepel / d2;
          dx *= f; dy *= f;
          a.vx += dx; a.vy += dy;
          b.vx -= dx; b.vy -= dy;
        }
      }

      for (const l of links) {
        if (!visible(l.source) || !visible(l.target)) continue;
        if (focus && focusSet.size > 0 && (!focusSet.has(l.source.id) || !focusSet.has(l.target.id))) continue;
        const dx = l.target.x - l.source.x;
        const dy = l.target.y - l.source.y;
        const dist = Math.sqrt(dx*dx + dy*dy) || 1;
        const target = 28 + Math.min(22, Math.sqrt(l.source.degree + l.target.degree) * 2);
        const diff = (dist - target);
        const fx = (dx / dist) * diff * strengthLink;
        const fy = (dy / dist) * diff * strengthLink;
        l.source.vx += fx; l.source.vy += fy;
        l.target.vx -= fx; l.target.vy -= fy;
      }

      for (const n of visNodes) {
        n.vx += (-n.x) * centerPull;
        n.vy += (-n.y) * centerPull;
        n.vx *= damping; n.vy *= damping;
        n.x += n.vx; n.y += n.vy;
      }
    }

    function draw() {
      ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--bg');
      ctx.fillRect(0, 0, W, H);

      const t = (performance.now() - replayAt) / 1000;
      const nodesAlpha = easeOutCubic(t / 1.0);
      const linksAlpha = easeOutCubic((t - 0.35) / 1.4);

      const query = q.value.trim().toLowerCase();
      const minD = parseInt(minDeg.value || '0', 10);
      const visible = (n) => n.degree >= minD && (!query || n.path.toLowerCase().includes(query));
      const focus = locked || hovered;
      const focusSet = new Set();
      if (focus && neighbors.has(focus.id)) {
        focusSet.add(focus.id);
        for (const nb of neighbors.get(focus.id)) focusSet.add(nb);
      }
      const isFocusMode = !!focus && focusSet.size > 0;

      ctx.save();
      ctx.translate(view.x, view.y);
      ctx.scale(view.k, view.k);

      const baseLink = getComputedStyle(document.documentElement).getPropertyValue('--link');
      const accent = getComputedStyle(document.documentElement).getPropertyValue('--accent');
      ctx.lineWidth = 1 / view.k;
      ctx.beginPath();
      ctx.strokeStyle = baseLink;
      ctx.globalAlpha = linksAlpha;
      for (const l of links) {
        if (!visible(l.source) || !visible(l.target)) continue;
        if (isFocusMode && (!focusSet.has(l.source.id) || !focusSet.has(l.target.id))) continue;
        ctx.moveTo(l.source.x, l.source.y);
        ctx.lineTo(l.target.x, l.target.y);
      }
      ctx.stroke();
      if (isFocusMode) {
        ctx.beginPath();
        ctx.strokeStyle = accent;
        ctx.lineWidth = 2 / view.k;
        ctx.globalAlpha = Math.max(linksAlpha, 0.65);
        for (const l of links) {
          if (!visible(l.source) || !visible(l.target)) continue;
          const isHit = (l.source.id === focus.id || l.target.id === focus.id);
          if (!isHit) continue;
          ctx.moveTo(l.source.x, l.source.y);
          ctx.lineTo(l.target.x, l.target.y);
        }
        ctx.stroke();
      }
      ctx.globalAlpha = 1;

      for (const n of nodes) {
        if (!visible(n)) continue;
        if (isFocusMode && !focusSet.has(n.id)) continue;
        const r = 3.2 + Math.min(12, Math.sqrt(n.degree) * 1.3);
        const isOrphan = n.degree === 0;
        const base = isOrphan
          ? getComputedStyle(document.documentElement).getPropertyValue('--orphan')
          : getComputedStyle(document.documentElement).getPropertyValue('--node');
        ctx.fillStyle = base;
        ctx.globalAlpha = nodesAlpha;
        ctx.beginPath();
        ctx.arc(n.x, n.y, r, 0, Math.PI * 2);
        ctx.fill();
        const isSelected = selected && selected.id === n.id;
        const isHovered = hovered && hovered.id === n.id;
        const isLocked = locked && locked.id === n.id;
        if (isSelected || isHovered || isLocked) {
          ctx.strokeStyle = accent;
          ctx.lineWidth = 2 / view.k;
          ctx.globalAlpha = 1;
          ctx.stroke();
        }
        ctx.globalAlpha = 1;
      }

      ctx.restore();
    }

    function tick() { step(); draw(); requestAnimationFrame(tick); }
    tick();
  </script>
</body>
</html>
"@

Set-Content -LiteralPath $OutHtml -Value $html -Encoding UTF8
Write-Output ([pscustomobject]@{ ok=$true; wikiPath=$WikiPath; outHtml=$OutHtml; outGraphJson=$OutGraphJson } | ConvertTo-Json -Depth 4)

if ($Open) {
  Start-Process $OutHtml | Out-Null
}
