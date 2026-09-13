# DCDart website rules

## Release and website consistency (required)

For every DCDart release, target, CLI, prerequisite, or distribution change, cross-check the current GitHub release/tag and assets, the actual Homebrew/Scoop manifests, the target registry, CLI help/version, and core documentation before changing or publishing the website. Update landing-page installation/status content, site/docs.html, and site/RELEASE-STATUS.md in the same work. Distinguish compiler host availability from generated-code targets, and linked targets from device-tested targets. Never infer package-manager availability from a target name. Run the release consistency check with live metadata before deploying; fix mismatches before declaring completion. Preserve current design while keeping all version numbers, commands, limitations, and links accurate.
