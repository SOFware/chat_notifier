# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.5] - 2026-02-02

### Added

- Dependabot configuration with weekly updates

### Changed

- Moved ENV variable setting `NOTIFY_APP_NAME` into the test helper
- Refactored method signatures for easier testing

### Removed

- OpenStruct dependency

## [0.2.4] - 2025-01-16

### Changed

- Add support for Ruby 3.4
- Check for Rails application before using Rails.application
