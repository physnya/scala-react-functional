# Full-project compliance review

Use this checklist for audits, large refactors, and final delivery. Read `compliance-rules.md` plus the rule files and pattern references for both sides first. Each section names the rule numbers it verifies; quote those numbers in findings.

## 1. Establish the project map

- Read dependency manifests, route entry points, backend `services/`, frontend `apis/`, `objects/`, `pages/`, and shared `components/`.
- List each backend service with its domain, owned tables, frontend-facing APIs, internal APIs, and route registration.
- List each page with its core state, derived display data, effects, and visible business regions.
- Identify the external-to-trusted identity conversion and the transaction boundary.

## 2. Search for functional-style violations

Run these searches with your agent's content-search tool when it has one (DSH `grep`, Claude Code `Grep`) or through the shell where it does not (Codex: `rg -n --glob '<include>' '<pattern>'`, falling back to `grep -rn`). All patterns below are ripgrep syntax. Inspect every hit in context: SQL, prose, and comments produce false positives.

- Scala: `\b(var|while)\b|scala\.collection\.mutable|unsafeRunSync|unsafeToFuture|\btry\b|\bcatch\b|\bfinally\b` (include `*.scala`).
- TypeScript: `\b(var|while|for)\b|\.push\(|\.splice\(|class \w+ extends (React\.)?Component` (include `*.{ts,tsx}`).
- TSX styling: `style=\{|document\.|window\.` (include `*.tsx`).

A Scala `for` comprehension that only composes effects is not a violation.

## 3. Check backend ownership and routes (rules 1–12, 20–33)

- All owned code sits under `services/<domain>/` or `services/system/`; any extra directory has a stated reason (rules 2–4).
- Each API operation is one `*Message.scala` with a `final case class`, constructor inputs, one response type, and `plan(connection): IO[Response]`; no forwarding layer and no extra execution wrapper (rules 20–23).
- API-specific types live under `objects/apiTypes/`; no empty request classes and no universal context injection (rules 24–27).
- Each service has one `XXRoutes`; route names are derived from message types; backend-only messages are absent from registration and have no frontend caller (rules 31–33).
- Token validation happens before a trusted `userId` enters a business message; frontend and backend shapes may differ intentionally at that boundary (rules 28–29).

## 4. Check objects and states (rules 13–19)

- Each meaningful object has one file with an adjacent companion; data structures are `final case class` with derived Circe codecs (rules 14–15).
- Enums centralize string conversion and codecs in their companion; no redundant `toApi`/`fromDatabase` family (rules 17–18).
- Finite states use enums, sealed types, or discriminated unions, and every branch makes omitted states visible (rules 19, 60).
- Objects contain no database access, service calls, randomness, or stateful workflows (rule 13).
- Imports are at the top of each file (rule 16).

## 5. Check persistence and effects (rules 34–38)

- Every table has its own folder with a table file and an initializer file; initialization is not inside API files or one monolithic initializer (rules 34–35).
- Each private `*Sql` value sits immediately before the public `IO[T]` method that executes it, and each table method encapsulates binding, execution, and row mapping (rules 36, 38).
- No method accepts arbitrary SQL; row mapping and table helpers are private; service utilities use `private[serviceName] def` (rules 7–8).
- Table functions hold persistence mechanics, not multi-step business policy (rule 37).
- JDBC resources use `Resource`; no `try`/`finally`, mutable builder, or cursor `while` loop remains (rules 20–22).
- Effects are delayed in `IO`, composed explicitly, and executed only by the application runtime; related operations reuse the passed connection (rule 22; `backend-scala.md`).

## 6. Check frontend structure and data flow (rules 39–47, 60)

- `components/ui/` contains only broadly reused primitives; page-only components, hooks, stores, objects, and pure functions stay beside their page (rules 39–40).
- A complex `index.tsx` immediately reveals the main business regions; nested folders exist only where complexity pays for the lookup cost (rules 44–47).
- Core state is minimal and updated immutably; display data is derived rather than duplicated; pure functions take explicit arguments and do not call hooks (rules 42, 60).
- Complex async pages model loading, ready, empty, error, and relevant operation states explicitly; a simple form keeps small local states (rule 60).
- Zustand stores are private and expose only needed `getXXXSnap`, `useXXX`, and `setXXX` functions (`frontend-react.md`).
- Cross-page data uses route/location input unless it is genuinely persistent shared core state (`frontend-react.md`).

## 7. Check frontend APIs and styling (rules 48–58)

- Frontend API folders match backend services where practical; each frontend-facing message has one caller class with explicit fields and `send()` (rules 48–49, 52).
- Shared infrastructure owns token handling, route-name derivation, sending, and common response handling (rules 50–51, 53).
- Tailwind provides styling; custom CSS has a concrete necessity (rule 55).
- Unused scaffold files, assets, CSS, dependencies, and directories are removed (rule 54).

## 8. Validate behavior

Run the project's existing formatter, compiler, type checker, tests, lint, and production build. Prefer the commands already declared in `build.sbt` and `package.json`; do not invent a new toolchain for the review.

Verify at least these flows when present:

- Public API request and response serialization.
- Token-protected request converting a token to a trusted identity.
- Authorization failure.
- Table method returning present and absent results.
- Transactional operation with multiple effects in order.
- React loading, ready, empty, and error rendering.
- A core-state update recomputing display data without mutation.
- Frontend API name matching the backend-derived name.

## 9. Report precisely

For each mandatory failure, report:

```text
Rule <number> — <short problem>
Location: <file and line>
Why: <specific boundary or functional invariant violated>
Fix: <smallest direct correction>
```

Close the review only when every touched rule has been checked, the validation commands above have run (or their absence is explained), and no unverified generated code remains. Keep optional taste comments out of the mandatory failure list; do not claim complete compliance while known failures remain.
