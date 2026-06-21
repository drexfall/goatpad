# Changelog

All notable changes to GOATpad are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.2.0] - 2026-06-21

### Added
- **Automatic session persistence.** Open tabs are now saved to local
  storage (localStorage on web, app storage on Android/desktop) and restored
  on the next launch — your work survives restarts and reopenings even if you
  never export the file to disk.
  - Each tab's content, associated file path/URI, and unsaved state are
    preserved, along with the active tab.
  - Edits are saved with a short debounce, and the session is flushed
    whenever the app is backgrounded or closed.
  - File-backed tabs re-attach their file watchers on restore (desktop).

## [1.1.2] - 2026-03-07

- Android file I/O and storage-permission improvements.

## [1.1.1] - 2026-03-07

- Maintenance release.

## [1.1.0] - 2026-02-19

- Responsive layout, share dialog, and expanded toolbar font options.

## [1.0.1] - 2026-02-13

- Upgrade to Flutter 3.35.3 in the release workflow.

## [1.0.0] - 2026-02-13

- Initial public release.
