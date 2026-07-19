# c-h-i-s.co.za — launch site

Static, dependency-free launch site for **C-H-I-S — Centralised Health Information System, by Urbanise Technology**. No build step, no frameworks, no external requests: upload the folder and it runs.

```
website/
  index.html          the whole site (single page, anchor navigation)
  assets/
    film-2min.mp4     the launch film, web-encoded 1280×536 (4.2 MB)
    film-60s.mp4      60-second cut, web-encoded (2.2 MB) — spare for social embeds
    poster.jpg        video poster frame
    *.jpg             photography and real product screens
```

Total ≈ 7 MB.

## Deploying

Any static host works — Azure Static Web Apps (fits the existing Azure/Marketplace posture), Netlify, Cloudflare Pages, S3+CloudFront, or plain nginx.

```bash
# Azure Static Web Apps (example)
az staticwebapp create -n chis-site -g <resource-group> -l westeurope
swa deploy ./website --env production
```

DNS: point the apex `c-h-i-s.co.za` at the host and 301 `www` → apex. Force HTTPS + HSTS.

## Before going live

1. **Register the domains** — `c-h-i-s.co.za` appeared unregistered on a DNS check (confirm with the registrar/ZACR and secure it); acquire `c-h-i-s.com` from the aftermarket. Add `.org.za` defensively.
2. **Wire the demo form** — it currently uses a `mailto:` action, which is a placeholder. Point it at a real handler (Azure Function, Formspree, or the CRM endpoint) and confirm `hello@c-h-i-s.co.za` exists.
3. **Add legal pages** — privacy policy and terms, both required before collecting form data under POPIA; link them in the footer.
4. **Remove the pre-launch checklist box** at the bottom of the demo section in `index.html`.
5. **Replace the pharmacy screen** (`assets/screen-pharmacy.jpg`) with a real capture once the QA environment is restored — it is currently the one designed stand-in.
6. **Genericisation sweep** — a demo surgeon's first name is faintly visible on the theatre screen; re-capture with clean data.
7. Analytics only if wanted, and if so, cookie-free (Plausible/Fathom) to keep the privacy story clean.

## Notes

- Light and dark themes follow the visitor's system preference.
- The film is `preload="metadata"` so the page loads fast; the poster carries the first impression.
- Copy, imagery and film all come from the approved V11 master — the site and the campaign speak the same language.
- Photography is AI-generated for the launch campaign. If the site is later used in a clinical or government tender context, consider replacing it with commissioned photography of real facilities (with consent), and keep the product screens as the factual proof.

---

## Current deployment

**Live (staging):** https://289glen-star.github.io/chis-launch-site/
**Repository:** https://github.com/289glen-star/chis-launch-site (public — required for GitHub Pages on a free account)

Deployed 19 July 2026. Two deliberate differences from the source copy in `~/Documents/Claude/CHIS/website/`:

1. **`noindex, nofollow`** is set (plus `robots.txt` disallow) — the brand is not trademark-cleared and `c-h-i-s.co.za` is not registered, so search engines must not index this address. **Remove both when the real domain goes live**, or the github.io copy will compete with it in search.
2. The internal pre-launch checklist box was removed from the public page.

### Updating the live site

```bash
cd <this folder>
# edit index.html / assets
git add -A && git commit -m "Update site" && git push
# Pages rebuilds automatically in ~1 minute
```

### Pointing c-h-i-s.co.za at it (once registered)

1. In the registrar's DNS: `ALIAS`/`ANAME` on the apex → `289glen-star.github.io`, and `CNAME` on `www` → `289glen-star.github.io`.
   (If the registrar has no ALIAS support, use the four GitHub Pages A records: 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153.)
2. Repo → Settings → Pages → Custom domain → `c-h-i-s.co.za` → Enforce HTTPS.
3. Remove the `noindex` meta tag and `robots.txt` disallow.

### Moving to Azure instead

The folder is a plain static site; Azure Static Web Apps (matching the CHIS Azure Marketplace posture) will serve it unchanged — `swa deploy . --env production`. Consider this before a government-facing launch: hosting under a personal GitHub account is fine for review, not for a production national-health brand.
