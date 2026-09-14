# Distribution trust

v0.1.3 was published without public Windows signing or macOS Developer ID
notarization. Checksums and successful Homebrew/Scoop runs do not establish OS
publisher trust. Do not disable Gatekeeper, Defender, SmartScreen or quarantine
as an installation fix.

The release-candidate workflow now has `distribution_trust=true`. This mode is
required for the next public macOS/Windows distribution. Ordinary development
builds remain explicitly `not-verified` in their embedded provenance. Neither
mode automatically publishes assets. Never upload development artifacts over
an existing stable version; bump the version and publish a new release.

## Credentials still required

Inspection on 2026-09-14 found no repository signing secrets or variables and
only an Apple Development identity locally. That identity is not a Developer
ID Application distribution identity. No signed release is claimed yet.

Apple Developer Program account owner:

- Create a Developer ID Application certificate and export its private key as
  an encrypted P12. Configure repository secrets `APPLE_CERTIFICATE_P12_BASE64`
  and `APPLE_CERTIFICATE_PASSWORD` through a secure channel, never a chat message.
- Configure `APPLE_SIGNING_IDENTITY` (Developer ID Application identity) and
  `APPLE_TEAM_ID` repository variables.
- Provision a notary API key: secret `APPLE_NOTARY_KEY_BASE64`; variables
  `APPLE_NOTARY_KEY_ID` and `APPLE_NOTARY_ISSUER`.

Windows publisher:

- Provision an identity-validated Azure Artifact Signing **Public Trust** profile.
- Configure OIDC federation for this repository's authorized release branch and
  grant only the Artifact Signing Certificate Profile Signer role needed.
- Set variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`,
  `AZURE_SIGNING_ENDPOINT`, `AZURE_SIGNING_ACCOUNT`, `AZURE_SIGNING_PROFILE`, and
  `DCDART_WINDOWS_PUBLISHER` (exact certificate Subject).
- No Azure password/client secret is needed. If another signing provider is
  selected, replace the signing step while preserving final verification.

## Release gates

1. Build and execute the packaged compiler regressions on macOS ARM64, Windows
   x86-64, Ubuntu 24.04 x86-64 and ARM64.
2. Sign the staged executable before archiving. macOS requires hardened runtime,
   secure timestamp, accepted notarization and Gatekeeper assessment. Windows
   requires a valid timestamped Authenticode signature from the expected subject.
3. Re-execute the final executable and record its SHA256/trust result in
   provenance. Archive and hash only those final bytes. Run full conformance
   on supported native test hosts; Windows currently has the packaged subset.
4. Before public publication, download/extract the archives on separate clean
   machines and repeat trust assessment and compile/link/run. Test browser
   downloads with quarantine/Mark of the Web preserved. CI shell downloads do
   not prove the browser/SmartScreen experience. Check Homebrew's actual bottled
   executable too; a separate bottle must not substitute an unsigned rebuild.
5. Publish new versioned assets, update Homebrew/Scoop hashes, run package-manager
   install CI, and synchronize release metadata, website docs and playground.

Standalone macOS CLI files and ZIPs cannot carry stapled notarization tickets;
the current flow needs an online Gatekeeper check. Offline installation remains
unverified; an independently signed/notarized/stapled installer is future work.
Windows signature validity does not guarantee SmartScreen reputation or override
an organization's application control policy. A compiler-generated executable
is a separate artifact: consumers must sign their own distributed applications.

Linux has no equivalent universal application-signing gate. Current host binaries
require glibc 2.39+, with Ubuntu 24.04 tested. Older glibc, musl/Alpine, macOS Intel
and Windows ARM64 are not validated host distributions. Checksums are integrity
checks, not independent publisher authentication or universal compatibility.

References: [Apple Developer ID](https://developer.apple.com/developer-id/),
[Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution),
[Microsoft SmartScreen](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation),
[Azure signing action](https://github.com/Azure/artifact-signing-action).
