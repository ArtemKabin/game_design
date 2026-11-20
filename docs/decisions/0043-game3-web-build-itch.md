# 0043: Game 3: single-threaded web export on itch.io, zipped build for the lecturer

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
Like Game 2 (0007) the demo is played in the browser on itch.io, and the build file is also sent to the lecturer. Game 2 used the threaded web template, which needs cross-origin isolation (SharedArrayBuffer) and fails in some browsers and in plain local hosting.

## Decision
Export preset "Web" with the single-threaded template (`variant/thread_support=false`), no PWA, desktop texture compression, `tests/*` excluded. Output goes to `game-3-atmosphere/build/web/`, zipped as `atmosphere-web.zip` for itch.io ("played in the browser", 1280 × 720 viewport, fullscreen button) and for the lecturer. The itch.io page lists the known issues and the requirements for the next tests.

## Consequences
Runs on itch.io without the SharedArrayBuffer setting and in more browsers. Single-threaded audio and physics share one thread; fine for this game size.
