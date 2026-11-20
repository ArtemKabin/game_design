# 0044: GitHub Spec Kit for larger features, headless smoke test and screenshot tool

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
The demo loop touched many systems at once under time pressure. We wanted the requirements written down before coding, and a quick way to check the loop without clicking through a whole week.

## Decision
Larger features go through GitHub Spec Kit (`.specify/`, skills `/speckit-*` in `.claude/skills/`): constitution (`.specify/memory/constitution.md`, KEEP IT SIMPLE, every option has a price, explainable failure, onboarding first, data in JSON), then spec, plan, tasks and implementation in `specs/NNN-name/`. `tests/loop_smoke_test.tscn` runs the whole loop headless, `tests/capture_screens.tscn` saves screenshots of all screens.

## Consequences
Small changes still go straight in with a decision entry. Spec files are reviewed in the PR like code.
