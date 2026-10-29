---
name: scala-react-functional-course
description: Design, implement, refactor, or review this course's Scala 3 backend and React TypeScript frontend under its mandatory functional-programming and software-organization rules. Use for course projects that require Cats Effect IO, typed service boundaries, declarative API routing, pure React data flow, Tailwind, or a compliance audit. Do not apply these course-specific constraints to unrelated Scala or React projects.
---

# Scala + React Functional Software Design

Build the whole project in the course's functional style. Treat compliance as a design constraint, not a cleanup pass.

## Authority and conflicts

Use this order when sources disagree:

1. `references/compliance-rules.md`, which preserves the requirements from `rules.txt`.
2. The lecture-derived requirements in this file and the backend/frontend references.
3. A class-note screenshot supplied with the current task.
4. Sample projects, after auditing each relevant pattern.
5. External references.

Never weaken a higher-priority rule to match sample code. Samples illustrate domains and workflows, not correctness. If a request conflicts with a mandatory rule, explain the conflict and implement the compliant interpretation unless the user explicitly changes the course rules.

## Required functional model

- Use immutable data and declarative transformations throughout. Do not introduce `var`, mutable collections, mutation-driven accumulators, imperative `for` loops, `while` loops, class components, or stateful domain objects.
- A Scala `for ... yield` or braceless `for` comprehension is allowed only to compose `IO` or another functional value. It must not be an imperative loop.
- Keep domain calculations pure. A pure function depends only on explicit inputs, returns a value, and performs no I/O, mutation, clock access, random generation, database work, network work, logging, or UI interaction.
- Push unavoidable effects to system boundaries and describe them with Cats Effect `IO`. Construct and combine effects without running them inside business code. The application runtime owns execution.
- Do not use `try`/`catch`/`finally` or `Try` for course-authored Scala control flow. Use `Resource`, `IO`, typed values, and effect error channels. `Option` remains valid for absence because the authoritative table rules explicitly require results such as `IO[Option[T]]`.
- Model finite states with closed types and exhaustive branching. Do not use unrestricted strings or booleans when a domain concept has a fixed set of states.
- Keep the implementation as small as the present requirement allows. Do not add speculative layers, forwarding services, generic frameworks, compatibility shims, or one-use abstractions.

## Workflow

1. Read `references/compliance-rules.md` before writing or reviewing project code. It is mandatory for every invocation.
2. Read `references/backend-scala.md` when the task touches Scala, APIs, services, authentication, SQL, tables, routing, transactions, or serialization.
3. Read `references/frontend-react.md` when the task touches React, TypeScript, pages, state, components, API callers, routing, or styling.
4. For a full-project review, also read `references/review-checklist.md` and inspect both dependency manifests and source trees before changing code.
5. Identify the business domains, trusted boundaries, effects, closed states, and page regions before choosing files. Make ownership visible in the directory tree.
6. Implement the smallest compliant structure. Preserve the main business steps in each API `plan` and the main business regions in each page `index.tsx`.
7. Verify with the project's formatter, type checker, compiler, tests, and build commands. Then run the structural and forbidden-pattern checks from the review checklist.

## Non-negotiable review behavior

Do not declare code compliant because it compiles or resembles a sample. Check every touched path against the relevant numbered rules. Report violations with the rule number, location, and smallest direct correction. Distinguish mandatory failures from optional improvements.

When generating code, every snippet and every created file must itself be compliant. Do not show a forbidden pattern as a negative example unless it is non-executable pseudocode clearly labeled `Noncompliant` and immediately replaced with the compliant form.

## Course architecture at a glance

- Backend: `services/<domain>/{api,objects,routes,tables,utils}` plus an owned infrastructure module such as `services/system/`.
- Behavior: one executable API message per operation, one `plan(connection): IO[Response]` entry, direct composition of other message plans and public table methods.
- Persistence: one folder per table, adjacent private SQL and public `IO[T]` table methods, separate initializer.
- Trust boundary: routes validate external tokens and construct messages with trusted internal identities.
- Frontend: shared `components/ui/` only for reusable UI primitives; page-specific components, hooks, objects, functions, and stores stay beside the page.
- React data flow: user actions update core state, pure functions derive display data, function components render it, and effects stay in hooks, event handlers, or API infrastructure.
- Styling: Tailwind is the declared style system. Avoid custom CSS unless the requirement cannot reasonably be expressed with Tailwind.

## Source provenance

This skill was synthesized from the course's `rules.txt`, lecture decks 1–5, the provided backend/frontend and student samples, and the referenced `Zzzaurak/Scala-course-skills` repository. The current source set did not contain the mentioned class-note screenshot; incorporate it later at priority level 3 without overriding the rules or decks.
