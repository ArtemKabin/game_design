# 0009: No fixed Person A / Person B split, both continue from the current state

* Date: 2026-10-04
* Status: accepted (replaces the role table in 0006; the scope cut in 0006 stays)
* Participants: both developers

## Context
Decision 0006 assigned foundation and Levels 0/1 to one developer and assets, storyboards and the final level to the other. In practice one developer built Level 0 and the first draft of Level 1 and the map logic, and the other is now picking up from there.

## Decision
No fixed role split. Both developers work on whatever is next on the Kanban board, continuing from the current state of the repo. The Kanban board lives on the GitHub repository.

## Consequences
Coordination happens through the board and pull requests, not through role ownership. The README no longer lists per-person responsibilities. Scene files still need an owner per task to avoid merge conflicts, but that is agreed per task, not per role.
