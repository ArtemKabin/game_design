# 0002: Godot with web export, self-hosted via GitHub Actions or itch.io

* Date: kickoff meeting, October 2026 (recorded 2026-10-04)
* Status: accepted
* Participants: Person A, Person B

## Context
First idea was Godot with web export. In the lecturer's intro meeting it came out that hosting Godot web exports on the lecturer's own server caused problems in previous semesters (the export needs a server that sets specific headers, and the course's hosting setup could not provide that reliably).

## Decision
We stay with Godot (4.7.x) and web export, but host the build ourselves, either through GitHub Actions (GitHub Pages) or on itch.io. Both options were briefly tested with small private projects beforehand.

## Consequences
We do not depend on the lecturer's server. We need an export pipeline in the repo at some point (GitHub Actions workflow or a documented manual itch.io upload). Features that do not work in the web export (threads, some file access) are to be avoided.
