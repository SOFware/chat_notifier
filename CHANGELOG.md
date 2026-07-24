# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-07-24

### Added

- Rate-limited posts retry once, honoring Slack's Retry-After (b2d5a6d)
- HTTP requests use explicit open/read timeouts so notifications cannot hang the suite (b2d5a6d)
- One Slack thread per breakage episode on a branch/PR, shared across parallel CI jobs, with the parent message maintained as a live status digest (38b8fff)
- Passing runs resolve open failure episodes, updating the thread parent to resolved (38b8fff)

### Fixed

- Slack API responses with ok:false are now logged instead of silently dropped (b2d5a6d)
- Error logging names the chatter class instead of leaking the webhook URL (b2d5a6d)
- Slack handler no longer activates without a webhook URL or bot token (b2d5a6d)
- Malformed NOTIFY_SLACK_THREAD_GROUP_SIZE falls back to the default (b2d5a6d)
- Replies are skipped when the parent response has no ts, instead of posting unthreaded (b2d5a6d)
- Notifications no longer fail silently: branch and sha now resolve from CI env or git instead of raising on the app name (8cb8603)

## [0.3.0] - 2026-07-24

### Added

- Threaded Slack failure notifications via a Slack bot token (NOTIFY_SLACK_BOT_TOKEN), grouping failing files into batched thread replies (e453cd0)
