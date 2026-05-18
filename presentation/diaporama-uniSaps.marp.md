---
marp: true
theme: default
paginate: true
style: |
  section {
    font-family: 'Segoe UI', system-ui, sans-serif;
    background: linear-gradient(135deg, #0d7377 0%, #212121 55%, #1a535c 100%);
    color: #fafafa;
  }
  h1 { font-size: 2.4em; letter-spacing: -0.02em; margin-bottom: 0.3em; text-shadow: 0 2px 24px rgba(0,0,0,0.4); }
  h2 { color: #7ec8c8; font-weight: 600; letter-spacing: 0.06em; text-transform: uppercase; font-size: 0.85em; }
  .hero { justify-content: center; text-align: center; }
  .big-icon { font-size: 6em; line-height: 1; opacity: 0.95; }
  .muted { opacity: 0.75; font-size: 0.72em; }
  section.lead img { opacity: 0; }
footer: uniSaps
---

<!-- _class: hero lead -->

<h2>Présentation</h2>
<div class="big-icon">📱 👔</div>

# uniSaps
### Garde-robe digitale · Mode · Communauté

---

<!-- _class: hero -->

<h2>Introduction</h2>

# Un problème ?
### Ce que tu portes.<br/><span style="opacity:.75">Ouvert. Organisé. Partageable.</span>

---

<h2>Analyse · Existant</h2>

# Hériter → innover

| 📸 Dispersé | ✅ uniSaps |
|:---:|:---:|
| Apps / réseaux | **Un lieu** |

---

<h2>Analyse · Existant</h2>

<div class="big-icon">🗂️ ➜ 🚀</div>

### Legacy gardé comme trace
<br/>**Flutter** au volant · API dédiée

---

<h2>Choix tech</h2>

<div style="display:flex;justify-content:space-around;align-items:flex-end;text-align:center;font-size:1.85em;line-height:1.6;">
<span>⚡ Flutter</span>
<span style="opacity:.85">🔥 Firebase</span>
<span style="opacity:.95">🐍 FastAPI</span>
<span style="opacity:.8">☁️ Vercel</span>
</div>

###### Riverpod · go_router · Firestore · Storage · Gemini

---

<h2>Fonctionnalités</h2>

<div class="big-icon">👗 🧵 👟 👒</div>

Dressing · Créations · Outfits swipe

---

<h2>Fonctionnalités</h2>

<div class="big-icon">📰 ❤️ 👥</div>

Inspiration · Amitiés · Badges 🔴

---

<h2>V1 vs V2</h2>

<table style="width:100%;font-size:1.15em;margin-top:.5em;border-collapse:separate;border-spacing:.6em;">
<tr><td style="background:rgba(255,255,255,.09);padding:.6em 1em;border-radius:14px;text-align:center;">V1</td><td style="opacity:.92;">MVP complet</td></tr>
<tr><td style="background:rgba(255,255,255,.14);padding:.6em 1em;border-radius:14px;text-align:center;"><b>V2</b></td><td style="opacity:.95;"><b>Premium · Social · Play</b></td></tr>
</table>

---

<h2>V1</h2>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.2em;font-size:1.25em;line-height:1.8;text-align:center;">
<div style="padding:1em;background:rgba(0,0,0,.2);border-radius:16px;">Auth</div>
<div style="padding:1em;background:rgba(0,0,0,.2);border-radius:16px;">Catalogue</div>
<div style="padding:1em;background:rgba(0,0,0,.2);border-radius:16px;">Outfits jour</div>
<div style="padding:1em;background:rgba(0,0,0,.2);border-radius:16px;">Build Android</div>
</div>

---

<h2>V2</h2>

<div class="big-icon">⭐ 🤝 📲</div>

Premium · Flux · Releases

---

<h2>Problèmes & apprentissages</h2>

<table style="width:100%;font-size:1.05em;line-height:1.55;margin-top:.4em;">
<tr><td>🔓</td><td>Forbidden → IAM / MIME</td></tr>
<tr><td>⏱️</td><td>Firestore vs Premium trop tôt</td></tr>
<tr><td>☁️</td><td>Serverless ≠ infini temps</td></tr>
</table>

##### Apprendre : messagerie claire + retries

---

<h2>Conclusions</h2>

<!-- _class: hero -->

<div class="big-icon">✅</div>

# Stack solide<br/>boucle valeur → store

<span class="muted">Merci</span>

---
