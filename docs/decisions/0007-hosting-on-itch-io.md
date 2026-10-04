# 0007: Web build is hosted on itch.io

* Date: 2026-10-04
* Status: accepted (narrows 0002)
* Participants: both developers

## Context
Decision 0002 left two hosting options open: GitHub Actions (GitHub Pages) or itch.io. itch.io has since been tested with a small private project and worked.

## Decision
The web export is published on itch.io. No GitHub Pages pipeline.

## Consequences
Export is a manual step: Godot web export, zip the output, upload to the itch.io project page with "This file will be played in the browser" checked. itch.io already sends the cross-origin headers the Godot web export needs (SharedArrayBuffer), so nothing special is required on our side. An export preset for Web should be added to the project early so a test build of Level 0 can be uploaded in week one.
