# Deployment status — 13 September 2026

- Live production URL: https://dcdart.pages.dev
- Cloudflare Pages project: `dcdart`, production branch `main`, direct upload through Wrangler.
- Requested domain: `dcdart.dotcorr.com`, added to the Pages project; awaiting external DNS validation.
- Authoritative DNS: Hostnet (`ns01.hostnet.nl`, `ns02.hostnet.nl`). The saved Cloudflare account has no `dotcorr.com` zone; moving nameservers is neither necessary nor part of this change.
- Required Hostnet record: `CNAME`, name `dcdart`, value `dcdart.pages.dev`. If an explicit A/AAAA/CNAME record already exists for that exact name, replace only that record. Do not change apex, wildcard, mail, or other subdomain records.
- Current DNS resolves `dcdart.dotcorr.com` to `216.239.34.21`, not Cloudflare Pages. No authenticated Hostnet browser session is available. Domain activation is not complete.
- After the DNS change, verify the Pages custom domain becomes active, then run `PLAYGROUND_URL=https://dcdart.dotcorr.com npm run test:browser`.

The checked-in Wrangler configuration deploys only `public/`. Native artifacts and historical captured outputs are not substituted for real execution. No production backend or billable compute is used by the playground.

Validation: 11 runtime test groups passed (including thousands of numerical and ARC assertions); all 7 Chromium browser flows passed locally and against https://dcdart.pages.dev, including mobile layout, runtime errors, timeouts, corrupted binaries and response headers.
