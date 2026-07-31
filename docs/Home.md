---
type: vault-home
project: neon-kitchen
status: active
updated: 2026-07-31
tags:
  - neon-kitchen
  - project-home
---

# Neon Kitchen

This directory is the canonical, version-controlled Obsidian vault for the
project knowledge that governs *Neon Kitchen*.

## Start Here

- [[Neon Kitchen - Game Design Document]] — player experience, mechanics,
  scope, and multi-agent design.
- [[technical_architecture|Technical Architecture]] — modularity boundaries,
  extension seams, code standards, and Phase 1 technical scope.
- [[Kitchen Lead]] — persistent agent role, coordination protocol, and
  authority boundaries.
- [[Kitchen Lead Worklog]] — current project snapshot, durable decisions,
  evidence, risks, and milestone context.
- [[adr/README|Architecture Decision Records]] — accepted technical decisions
  and the template for new ADRs.

## Systems of Record

| Concern | Canonical location |
|---|---|
| Game design | [[Neon Kitchen - Game Design Document]] |
| Architecture guidance | [[technical_architecture\|Technical Architecture]] |
| Accepted architecture decisions | `adr/` |
| Agent operating definitions | `agents/` |
| Durable project memory | [[Kitchen Lead Worklog]] |
| Executable work | [GitHub Issues](https://github.com/rkhanna24/NeonKitchen-godot/issues) |
| Status and sequencing | [Neon Kitchen Development Project](https://github.com/users/rkhanna24/projects/1) |
| Implementation | [NeonKitchen-godot](https://github.com/rkhanna24/NeonKitchen-godot) |

The root `AGENTS.md` is intentionally outside this vault so repository coding
agents discover it automatically. It links back into these documents.

Do not recreate issue status or routine task history in the Kitchen Lead
Worklog. GitHub remembers the work; the worklog remembers durable reasoning.
