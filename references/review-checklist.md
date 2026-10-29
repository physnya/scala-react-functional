# Full-project compliance review

Use this checklist for audits, large refactors, and final delivery. Read the backend and frontend references first when both sides are present.

## 1. Establish the project map

- Read dependency manifests, route entry points, backend `services/`, frontend `apis/`, `objects/`, `pages/`, and shared `components/`.
- List each backend service with its domain, owned tables, frontend-facing APIs, internal APIs, and route registration.
- List each page with its core state, derived display data, effects, and visible business regions.
- Identify the external-to-trusted identity conversion and the transaction boundary.

## 2. Search for functional-style violations

Use searches as leads, then inspect context. Do not flag Scala `for` comprehensions that only compose effects.

```bash
rg -n --glob '*.scala' '\b(var|while)\b|scala\.collection\.mutable|unsafeRunSync|unsafeToFuture|\btry\b|\bcatch\b|\bfinally\b'
rg -n --glob '*.{ts,tsx}' '\b(var|while|for)\b|\.push\(|\.splice\(|class .*extends React\.Component|class .*extends Component'
rg -n --glob '*.tsx' 'style=\{|document\.|window\.'
```

Check every result. SQL text containing `for update` and prose containing these words are not programming violations.

## 3. Check backend structure

- All owned code is under `services/<domain>/` or `services/system/`.
- Service directories use only the allowed folders unless an extra directory has a stated reason.
- Every API operation is one `*Message.scala` file with a `final case class`, constructor inputs, one response type, and `plan(connection): IO[Response]`.
- No forwarding-only service layer or redundant execution method exists.
- Backend-only APIs are absent from route registration and have no unnecessary frontend caller.
- Every service has one `XXRoutes`; the top router concatenates service lists.
- Route names are derived, not repeated strings.
- Token validation happens before trusted identity enters a business message.

## 4. Check objects and states

- Each meaningful object has one file and an adjacent companion.
- Data structures are `final case class` with derived Circe codecs.
- Enums centralize string conversion and codecs in companions.
- Finite states use enums, sealed types, or discriminated unions with exhaustive handling.
- Domain identifiers and states are not indistinguishable raw primitives.
- Objects do not access databases, services, randomness, or stateful workflows.
- API-specific response structures live under `objects/apiTypes/`.

## 5. Check persistence and effects

- Every table has its own folder, table file, and initializer file.
- Each private `*Sql` value sits immediately before its public `IO[T]` method.
- Public table methods encapsulate binding, execution, and mapping and do not accept arbitrary SQL.
- Row mapping and table helpers are private. Service utilities use `private[serviceName] def`.
- Table functions contain persistence mechanics, not multi-step business policy.
- JDBC resources use `Resource`; no `try`/`finally`, mutable builder, or cursor `while` loop remains.
- Effects are delayed in `IO`, composed explicitly, and executed only by the application runtime.
- Related operations reuse the passed connection so transaction intent stays visible.

## 6. Check frontend structure and data flow

- `components/ui/` contains only broadly reusable primitives.
- Page-only components, hooks, stores, objects, and pure functions stay beside the page.
- Complex `index.tsx` files reveal the main business regions.
- Nested page folders exist only where complexity pays for the lookup cost.
- Core state is minimal and updated immutably. Display data is derived rather than duplicated.
- Complex async pages model loading, ready, empty, error, and relevant operation states explicitly.
- Pure functions do not call hooks or perform I/O. Components are function components.
- Zustand stores are private and expose only needed `getXXXSnap`, `useXXX`, and `setXXX` functions.
- Cross-page data uses route/location input unless it is genuinely persistent shared core state.

## 7. Check frontend APIs and styling

- Frontend API folders match backend services where practical.
- Each frontend-facing message has a corresponding API class with explicit fields and `send()`.
- Shared infrastructure owns token handling, route-name derivation, sending, and common response handling.
- Tailwind provides styling; custom CSS has a concrete necessity.
- Unused scaffold files, assets, CSS, dependencies, and directories are removed.

## 8. Validate behavior

Run the project's existing formatter, compiler, type checker, tests, lint, and production build. Prefer the commands already declared in `build.sbt` and `package.json`; do not invent a new toolchain for the review.

Verify at least these flows when present:

- Public API request and response serialization.
- Token-protected request converting token to trusted identity.
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

Do not mix optional taste comments into the mandatory failure list. Do not claim complete compliance while known failures or unverified generated code remain.
