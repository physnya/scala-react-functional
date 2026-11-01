---
name: scala-react-functional-course
description: Use when a Scala 3 + React TypeScript course project must satisfy its mandatory functional-programming and software-organization rules (Cats Effect IO, declarative API messages, typed service and table boundaries, pure React data flow, Tailwind), or when auditing such a project for compliance. Do not apply these course-specific constraints to unrelated Scala or React projects.
whenToUse: A course assignment, implementation, refactor, or compliance review whose project is governed by the 60 numbered rules indexed in references/compliance-rules.md.
metadata:
  version: 0.2.1
  license: GPL-3.0
  source: https://github.com/physnya/scala-react-functional
---

# Scala + React Functional Software Design

Apply this skill only to the course's project. Build the whole project in the course's functional style, and treat compliance as a design constraint rather than a cleanup pass.

## Authority and conflicts

Use this order when sources disagree:

1. `references/compliance-rules.md` with the numbered rule files it indexes; they define the course's mandatory numbered requirements.
2. The lecture-derived requirements in this file and in `references/backend-scala.md` and `references/frontend-react.md`.
3. A class-note screenshot supplied with the current task.
4. Sample projects, after auditing each relevant pattern.
5. External references.

Never weaken a higher-priority rule to match sample code. Samples illustrate domains and workflows, not correctness. If a request conflicts with a mandatory rule, explain the conflict and implement the compliant interpretation unless the user explicitly changes the course rules.

## Loading the references

The skill's base directory contains these files. Resolve every relative path below against it, and read them with your file-read tool.

- `references/compliance-rules.md` — mandatory on every invocation. It states the authority order, indexes the numbered rules, lists cross-cutting rules, and holds the lecture interpretation rules.
- `references/compliance-backend.md` — read for Scala, APIs, services, authentication, SQL, tables, routes, transactions, or serialization (rules 1–38).
- `references/backend-scala.md` — read after the backend rules for concrete patterns and code.
- `references/compliance-frontend.md` — read for React, TypeScript, pages, state, components, API callers, routing, or styling (rules 39–60).
- `references/frontend-react.md` — read after the frontend rules for concrete patterns and code.
- `references/review-checklist.md` — read for a full-project audit; it holds the procedures, search patterns, verification flows, and report format.

Skip the files for the side a task does not touch.

## Required functional model

- Use immutable data and declarative transformations throughout. Do not introduce `var`, mutable collections, mutation-driven accumulators, imperative `for` loops, `while` loops, class components, or stateful domain objects.
- A Scala `for ... yield` or braceless `for` comprehension is allowed only to compose `IO` or another functional value. It must not be an imperative loop.
- Keep domain calculations pure: a pure function depends only on explicit inputs, returns a value, and performs no I/O, mutation, clock access, random generation, database work, network work, logging, or UI interaction.
- Push unavoidable effects to system boundaries and describe them with Cats Effect `IO`; compose effects without running them inside business code. The application runtime owns execution. Do not use `try`/`catch`/`finally` or `Try` for course-authored Scala control flow; use `Resource`, `IO`, typed values, and effect error channels. `Option` remains valid for absence.
- Keep the implementation as small as the present requirement allows. Do not add speculative layers, forwarding services, generic frameworks, compatibility shims, or one-use abstractions.

## Workflow

1. Load the references that match the task side (above).
2. Identify the business domains, trusted boundaries, effects, closed states, and page regions before choosing files; make ownership visible in the directory tree.
3. Implement the smallest compliant structure. Keep the main business steps visible in each API `plan` and the main business regions visible in each page `index.tsx`.
4. Verify with the project's formatter, type checker, compiler, tests, and build commands; then run the structural and forbidden-pattern checks from the review checklist.

## Non-negotiable review behavior

- Do not declare code compliant because it compiles or resembles a sample. Check every touched path against the relevant numbered rules, and name the rule number for each violation.
- Report each mandatory failure with the rule number, location, why the boundary is violated, and the smallest direct correction; keep optional improvements in a separate list.
- When generating code, every snippet and every created file must itself be compliant. Never show a forbidden pattern except as non-executable pseudo-code labeled `Noncompliant` and immediately replaced with the compliant form.
- Do not claim complete compliance while known failures or unverified generated code remain.

## Architecture map

- Backend ownership, boundaries, and trust conversion: rules 1–12.
- Backend objects, closed types, and serialization: rules 13–19.
- Backend API messages, effects, and routing: rules 20–33.
- Tables and persistence: rules 34–38.
- Frontend ownership and page structure: rules 39–47.
- Frontend API, types, styling, and state: rules 48–60.
