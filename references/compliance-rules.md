# Authoritative compliance rules

These numbered requirements define the course's mandatory rules. Apply all rules relevant to the project. When another reference or a sample conflicts, this file and the rule files it indexes win.

## Where each rule lives

| Rules | Scope | File |
|---|---|---|
| 1–12 | Backend ownership, allowed boundaries, trust conversion | `compliance-backend.md` |
| 13–19 | Backend objects, serialization, closed types | `compliance-backend.md` |
| 20–33 | Backend API messages, effects, routing | `compliance-backend.md` |
| 34–38 | Tables and persistence | `compliance-backend.md` |
| 39–47 | Frontend ownership and pages | `compliance-frontend.md` |
| 48–60 | Frontend API, types, styling, state | `compliance-frontend.md` |

Rule numbers are global and stable: cite "rule 36" wherever the rule lives. Do not renumber rules when editing a file.

## Cross-cutting rules

These rules matter even when a task touches only one side: 19 (closed types on both backend and frontend), 28–29 (the trust boundary and the intentional frontend/backend shape difference), 47 (modularity must reduce lookup cost), 59 (documentation folder), and the interpretation rules below.

## Interpretation rules from the lectures

- The course bans mutation-driven programming, not Scala effect comprehensions. `for` composition over `IO` is allowed and encouraged; imperative iteration is not.
- The course requires the entire project to use the functional model. Boundary code may interact with mutable external systems, but the interaction must stay delayed inside `IO`, `Resource`, React effects, event handlers, or API infrastructure.
- “Do not use primitive types” means do not use naked primitives for distinct business concepts. Primitive fields remain legitimate inside small domain value wrappers and at serialization/storage boundaries.
- “Microservice” describes modular business ownership in this course. Do not split a small assignment into separately deployed network services unless the task requires it.
- Strong types, declarative structure, and modular ownership are the three organizing principles. Prefer a structure that an AI can modify locally and a human can inspect without tracing hidden control flow.
