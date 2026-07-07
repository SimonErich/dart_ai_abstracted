# Releasing

The package publishes to pub.dev from a git tag through GitHub Actions
(`.github/workflows/publish.yaml`, OIDC, no stored token). Automated publishing
is set up on pub.dev with the tag pattern `v{{version}}`.

## Cut a release

1. Pick the version. Before 1.0.0, a breaking change is a MINOR bump and a
   feature or fix is a PATCH bump.
2. Update `version:` in `pubspec.yaml` and add a `## <version>` section at the
   top of `CHANGELOG.md`. Mark breaking bullets with **BREAKING**.
3. Run the checks locally: `dart format --output=none --set-exit-if-changed .`,
   `dart analyze --fatal-infos --fatal-warnings`, `dart test`, and
   `dart pub publish --dry-run` (zero warnings, and eyeball the file list).
4. Commit, then tag and push:

   ```sh
   git tag v<version>
   git push origin main --tags
   ```

   The tag triggers the publish workflow.

## After a bad release

A published version is permanent; plan around that, not around deletion.

- If a version has a serious problem, retract it within 7 days on the pub.dev
  admin page. It stays visible but is badged RETRACTED and pub stops selecting
  it by default.
- If the package is abandoned, mark it discontinued on pub.dev (optionally
  naming a replacement) rather than trying to remove it.
