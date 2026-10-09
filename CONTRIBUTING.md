# Contributing

This is an early Android-first Flutter project. Small, focused contributions are welcome.

## Setup

Install Flutter 3.41.5 (Dart 3.11.3), Android SDK and JDK 17. Run `flutter pub get` in the root and example. Use the synthetic receipt in `example/test_documents`.

## Before opening a pull request

1. Explain the user-visible problem and intended behaviour.
2. Keep the change focused and add a regression test for behaviour that can fail.
3. Run the commands in the README's Development section.
4. For OCR, camera, crop or sharing changes, describe physical-device testing: Android version, device and what you observed. Unit tests cannot validate native OCR.
5. Update documentation/changelog if the public behaviour or API changes.

Use existing formatting and avoid unrelated dependency upgrades. Do not submit credentials, generated APKs, real customer documents, or code you do not have permission to share. Contributions are made under the project's MIT licence.

## Reporting bugs

Include reproduction steps, expected/actual behaviour, Flutter/Dart version, device/Android version, and a synthetic image when relevant. For text export, distinguish Text document from Original scan. Remove personal information from logs.

For significant new features, discuss the use case in an issue before a large implementation. This release does not promise stable APIs or a support response time.
