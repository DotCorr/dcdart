# Deployment status — 13 September 2026

- Production URL: https://dcdart.dotcorr.com
- Pages fallback: https://dcdart.pages.dev
- Cloudflare Pages project: `dcdart`, production branch `main`, direct upload through Wrangler.
- Authoritative DNS: Cloudflare (`apollo.ns.cloudflare.com`, `elisabeth.ns.cloudflare.com`). The domain owner moved the zone from Hostnet; Cloudflare reports the zone active.
- Custom domain attached to Pages. Cloudflare DNS has a proxied `CNAME dcdart → dcdart.pages.dev`, TTL Auto. Existing apex, wildcard, mail, and unrelated subdomain records were preserved.
- HTTPS returns 200 with certificate verification enabled at Cloudflare's authoritative address. DNS verification is active; Pages certificate validation was still pending in the API at the latest check, although verified HTTPS already works.
- DNS propagation caveat: the local recursive resolver still cached the old `216.239.34.21` address during validation. Public/authoritative DNS returned Cloudflare. Custom-domain tests therefore mapped only this hostname to its verified Cloudflare address, with normal TLS verification retained. No permanent local DNS override was installed.

The checked-in Wrangler configuration deploys only `public/`. Native artifacts and historical captured outputs are not substituted for real execution. No production backend or billable compute is used by the playground.

Validation: 11 runtime test groups passed (including thousands of numerical and ARC assertions); all 7 Chromium browser checks passed locally and against https://dcdart.pages.dev. The same 7 checks passed on https://dcdart.dotcorr.com using the temporary DNS mapping described above, including mobile layout, runtime errors, timeouts, corrupted binaries and response headers. The request-header check was rerun after applying the same DNS mapping to Node's resolver.

For routine verification after DNS propagation: `PLAYGROUND_URL=https://dcdart.dotcorr.com npm run test:browser` from `site/`.
