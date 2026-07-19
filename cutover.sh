#!/usr/bin/env bash
# C-H-I-S — cut the live site over from GitHub Pages staging to c-h-i-s.co.za.
# Run this ONLY after the GoDaddy DNS records below resolve to GitHub.
#
#   Apex  c-h-i-s.co.za   A  185.199.108.153
#                         A  185.199.109.153
#                         A  185.199.110.153
#                         A  185.199.111.153
#   www                   CNAME  289glen-star.github.io
#
set -euo pipefail
REPO="289glen-star/chis-launch-site"
DOMAIN="c-h-i-s.co.za"

echo "==> 1/5  Verifying DNS points at GitHub Pages"
GH_IPS="185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153"
RESOLVED="$(dig +short A "$DOMAIN" | sort | tr '\n' ' ')"
echo "    $DOMAIN -> ${RESOLVED:-(nothing)}"
MATCH=0
for ip in $GH_IPS; do case "$RESOLVED" in *"$ip"*) MATCH=$((MATCH+1));; esac; done
if [ "$MATCH" -lt 1 ]; then
  echo "    DNS is not pointing at GitHub Pages yet. Add the records above at GoDaddy, wait for propagation, re-run."
  exit 1
fi
echo "    OK ($MATCH/4 GitHub IPs present)"

echo "==> 2/5  Telling GitHub Pages about the custom domain"
printf '%s\n' "$DOMAIN" > CNAME
gh api -X PUT "repos/$REPO/pages" -f "cname=$DOMAIN" >/dev/null 2>&1 || true

echo "==> 3/5  Making the site indexable (staging protection off)"
python3 - <<'GUARD'
import sys
h=open("index.html").read()
if "Pre-launch checklist" in h:
    sys.exit("ABORT: internal pre-launch checklist still present in index.html")
GUARD

python3 - <<'PY'
import re
h = open("index.html").read()
h = h.replace('<meta name="robots" content="noindex, nofollow">\n', '')
# canonical now that a real domain exists
if 'rel="canonical"' not in h:
    h = h.replace('<meta property="og:type" content="website">',
                  '<meta property="og:type" content="website">\n<meta property="og:url" content="https://c-h-i-s.co.za/">\n<link rel="canonical" href="https://c-h-i-s.co.za/">')
h = h.replace('content="assets/poster.jpg"', 'content="https://c-h-i-s.co.za/assets/poster.jpg"')
open("index.html","w").write(h)
PY
printf 'User-agent: *\nAllow: /\nSitemap: https://c-h-i-s.co.za/sitemap.xml\n' > robots.txt
cat > sitemap.xml <<XML
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://c-h-i-s.co.za/</loc><changefreq>monthly</changefreq><priority>1.0</priority></url>
</urlset>
XML

echo "==> 4/5  Committing and pushing"
git add -A
git -c user.name="Glen" -c user.email="me@glenvin.com" commit -q -m "Cut over to c-h-i-s.co.za: custom domain, indexable, canonical + sitemap" || echo "    (nothing to commit)"
git push -q origin main
echo "    pushed — Pages rebuilds in ~1 min"

echo "==> 5/5  Requesting HTTPS enforcement (may need a few minutes for the certificate)"
sleep 45
gh api -X PUT "repos/$REPO/pages" -F "https_enforced=true" >/dev/null 2>&1 \
  && echo "    HTTPS enforced" \
  || echo "    Certificate still provisioning — re-run: gh api -X PUT repos/$REPO/pages -F https_enforced=true"

echo
echo "Done. Check: https://$DOMAIN/"
