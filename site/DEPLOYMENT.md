# Deployment status — 13 September 2026

- Production URL: https://dcdart.dotcorr.com
- Pages fallback: https://dcdart.pages.dev
- Cloudflare Pages project: `dcdart`, production branch `main`, direct upload through Wrangler.
- Authoritative DNS: Cloudflare (`apollo.ns.cloudflare.com`, `elisabeth.ns.cloudflare.com`). The domain owner moved the zone from Hostnet; Cloudflare reports the zone active.
- Custom domain attached to Pages. Cloudflare DNS has a proxied `CNAME dcdart → dcdart.pages.dev`, TTL Auto. Existing apex, wildcard, mail, and unrelated subdomain records were preserved.
- Domain, DNS verification, and certificate validation are all active in the Cloudflare Pages API. HTTPS returns 200 with normal DNS and certificate verification enabled.
- The local ISP resolver cached the former host after the nameserver migration. The Mac’s Wi-Fi DNS was switched from automatic ISP DNS to Cloudflare (`1.1.1.1`, `1.0.0.1`), and its local DNS cache was flushed. No hosts-file or per-host address override is used. To restore automatic Wi-Fi DNS later: `networksetup -setdnsservers Wi-Fi Empty`.
- Landing page, playground, and documentation now use a restrained dark design based on the requested Cursor reference: compact typography, neutral surfaces, quiet navigation, and the functional playground as the main visual.

The checked-in Wrangler configuration deploys only `public/`. Native artifacts and historical captured outputs are not substituted for real execution. No production backend or billable compute is used by the playground.

Validation: 11 runtime test groups passed (including thousands of numerical and ARC assertions). After the redesign, all 7 Chromium browser flows passed locally and on https://dcdart.dotcorr.com using ordinary DNS and TLS verification, with no test resolver override. Coverage includes changed inputs, ARC accounting, runtime traps, timeouts, corrupted binaries, mobile layout, response headers, and missing pages. The published site also opened successfully in the Codex in-app browser.

For routine verification after DNS propagation: `PLAYGROUND_URL=https://dcdart.dotcorr.com npm run test:browser` from `site/`.
