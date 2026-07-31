# Architecture Decision Records

Use this directory for decisions that materially change the technical
architecture.

Create an ADR before adding:

- a persistent Autoload;
- a project-wide ECS or global event bus;
- C# or another implementation language;
- a new canonical content format;
- a new domain dependency;
- an incompatible command, event, save, replay, or content-schema change;
- a multiplayer authority or replication model.

## Naming

Use:

```text
NNNN-short-decision-title.md
```

Example:

```text
0001-pin-godot-version.md
```

## Template

```markdown
# ADR NNNN: Decision title

- Status: Proposed | Accepted | Superseded
- Date: YYYY-MM-DD
- Deciders:
- Supersedes:

## Context

What decision is needed, and what constraints or evidence matter?

## Decision

What are we choosing?

## Alternatives Considered

What materially different options were considered?

## Consequences

What becomes easier, harder, required, or deferred?

## Verification

How will we know the decision is working?
```

Do not rewrite an accepted ADR to change history. Add a new ADR that supersedes
it.
