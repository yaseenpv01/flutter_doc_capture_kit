# Release candidate: 0.1.0-dev.1

## Prepared locally

- Package metadata and minimum SDK aligned with tested Flutter 3.41.5 / Dart 3.11.3.
- MIT licence, contribution instructions, issue/PR templates and CI workflow.
- Public API usage examples and prototype limitations.
- Package exclusions for local configuration, builds, credentials and Android example scaffolding.

## Before public publication

1. GitHub owner verified as `yaseenpv01` (https://github.com/yaseenpv01). Public source repository: https://github.com/yaseenpv01/flutter_doc_capture_kit. Pub.dev publication remains pending.
2. Repository and issue tracker URLs are configured in pubspec.yaml. Verify the GitHub CI run before tagging a release.
3. The package is renamed to `flutter_doc_capture_kit`. Its pub.dev API lookup returned HTTP 404 on 2026-10-09. Recheck before publishing; this does not reserve the name.
4. Complete the physical-device acceptance checklist and review included code/licences. The native ML Kit engine remains separately licensed.
5. Run CI on GitHub and check the clean-checkout Android build.
6. Run `flutter pub publish --dry-run` and inspect the exact archive listing. Resolve metadata warnings.
7. Review the release notes. Publish only when explicitly ready; preparation and a dry run do not upload a package.
8. Create the prerelease tag/release and publish to pub.dev using the owner's account if requested.

The public source repository is prepared for upload. No pub.dev publishing command without `--dry-run` has been run. The connected GitHub account is verified; a pub.dev publishing account has not been configured by this task.

## References

- https://dart.dev/tools/pub/publishing
- https://github.com/subosito/flutter-action
