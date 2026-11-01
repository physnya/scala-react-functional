# Backend compliance rules (1–38)

Authoritative numbered requirements for backend work, split from `compliance-rules.md` without changing their numbers. Read `compliance-rules.md` first for the authority order, the cross-cutting rules, and the lecture interpretation rules.

## Backend ownership and allowed boundaries

1. Public cross-service API messages and public table methods are valid call boundaries. Table ownership, SQL, private helpers, identity trust boundaries, and transaction requirements remain explicit.
2. Put every backend service in one folder under `services/`. Give each service a clear business domain and make ownership of APIs, objects, routes, tables, and internal implementation visible.
3. A service folder should normally contain only `api/`, `objects/`, `routes/`, `tables/`, and `utils/`. Explain any additional directory. Add subpaths under those directories only when complexity justifies them.
4. Shared infrastructure also needs ownership under `services/`, normally in `services/system/`. Database configuration, server configuration, defaults, transaction/session tools, application startup, and shared routing stay separate from business responsibilities. Explain extra system directories.
5. Ownership means maintenance and encapsulation, not a ban on calls. Any backend API may call a public, encapsulated table method from any service. SQL and private helpers stay in the owning service.
6. A service may expose API messages and encapsulated table methods. Public table `def`s are callable by APIs anywhere in the backend.
7. Each table method encapsulates SQL, binding, execution, and row mapping. Give it a meaningful name, typed inputs, and an `IO[T]` result. Callers must not receive SQL for later execution or pass arbitrary SQL to bypass the table boundary.
8. SQL values, row-mapping helpers, and other internals use private visibility. Every helper function in a service's `utils/` uses `private[serviceName] def` and remains usable only within that service.
9. An API `plan` may call any backend API message's `plan`, any service's public non-SQL table method, and helper functions from its own service's `utils/`.
10. Call another API by constructing its message and invoking `plan(connection)`. Call a table through its public method. Do not add a forwarding API or service merely to cross a service boundary.
11. The user/account service owns roles, permissions, login state, sessions, and token parsing. Other services may obtain identity and permission decisions through its APIs. They may also read public user/session table methods, but raw data does not automatically prove authorization. The caller still applies an explicit permission rule.
12. Extract a service-local utility only when multiple APIs/utilities reuse the logic or an API `plan` needs splitting for readability. Keep the main steps and important effects visible in the API file. Expose cross-service business capability as an API message and cross-service persistence as a public table method, not as a global helper.

## Backend objects and closed types

13. Keep `objects/` pure and small. It contains cross-boundary data structures, enums, domain value types, and serialization. Do not put database access, service calls, permission checks, random ID generation, stateful workflows, unrelated behavior, or table-row mapping there. Avoid `random`, `fromStored`, `fromDatabaseRow`, and `toDatabaseRow` unless they genuinely define serialization or the value itself.
14. Define data structures as `final case class` and derive Circe `Encoder` and `Decoder` in the same-named companion object.
15. Put each meaningful object in its own file. Keep a type and its companion together. Do not create broad `Models.scala` or `DomainObjects.scala` aggregates.
16. Put imports at the top of each file whenever possible.
17. Keep enum serialization simple. When API and database representations match, one companion `toString` and one `fromString` are enough. Do not create parallel `toApi`, `fromApi`, `toDatabase`, `fromDatabase`, or similar methods without a real representational difference.
18. Put enum conversion and codecs in the companion object. Enum cases carry data only. Encoders reuse `toString`; decoders reuse `fromString`, including normalization and invalid-value handling.
19. Represent finite states with closed types such as Scala enums, sealed traits, TypeScript discriminated unions, or literal unions. Branching must make omitted states visible. Do not use unnecessarily complex type machinery.

## Backend API messages and effects

20. Put each API operation in its own file as the main executable business unit. Name it with the `Message` suffix. Use a `final case class`, place inputs in constructor parameters, extend `APIMessage[Response]`, and implement `plan(connection: Connection): IO[Response]`.
21. `plan(connection)` is the single necessary public execution entry. Do not add `execute` or another wrapper unless it establishes a real boundary or required shared mechanism.
22. Every API `plan` returns `IO[Response]`. Compose database access, validation, authorization, and business operations explicitly inside the effect plan. Calls to other messages and table methods remain visible steps.
23. Do not create a service layer that only forwards `APIMessage -> Service -> Table`. Prefer direct `APIMessage -> Table` composition. Add a service layer only for genuine reusable domain logic that preserves boundaries.
24. Separate domain objects from transport types. Put API-specific structures in `objects/apiTypes/`. Each API has one response type; combine multiple response fields into one response structure there.
25. Do not create empty request classes merely to satisfy a generic shape.
26. A message with no business request input extends `NoRequestMessage[Response]` and still exposes `plan(connection)`. Do not add a dummy request wrapper.
27. Model actual dependencies. Message constructors carry business inputs and `plan` normally receives only `connection`. Do not inject a universal context, request metadata, or authentication metadata into every API.
28. At the router boundary, validate and parse an external token through the user/account service or a public table method. Only then construct the business message with a trusted `userId`. Never trust a frontend-provided `userId` as authenticated identity.
29. Frontend and backend message shapes may intentionally differ at the trust boundary. A frontend token may become a trusted backend `userId`; do not force identical fields when that would weaken security.
30. Keep API categories small. Use `APIMessage[Response]`, `NoRequestMessage[Response]`, and `APIWithTokenMessage[Response]` only where their real differences apply. Do not create a separate hierarchy for every permission/request combination.
31. Derive API route names from message type names with one shared rule. Remove the `Message` suffix and normalize consistently on both sides. Do not repeat route-name strings in each message.
32. Keep the router declarative. It receives an API name, finds registration, deserializes input, performs required token-to-identity conversion, constructs the message, invokes `plan(connection)`, and serializes the result. It contains no business logic.
33. Give each service one `XXRoutes` file that registers frontend-facing API messages. Do not register backend-only messages or create frontend callers for them. The top-level router concatenates service registration lists instead of repeating every endpoint.

## Tables and persistence

34. Place each table under its owning service, normally the service where it first appears in the business flow. Keep schema, indexes, constraints, initialization, public methods, row mapping, and table-specific internals in that table module. Do not initialize tables inside API files or one unrelated monolithic initializer.
35. Give each table its own folder with `XXTable.scala` and `XXTableInitializer.scala`. Additional grouping is allowed when complexity justifies it, but table definition and initialization remain easy to find together.
36. Pair one private SQL `val` ending in `Sql` with one table `def`, adjacent in the file. The `def` performs the operation and returns `IO[T]`, including `IO[Option[T]]`, `IO[List[T]]`, or other meaningful results. Public methods expose operations, never SQL.
37. Keep heavy business logic out of table methods. Put it in API messages or the owning service's private utilities. Cross-service callers use only public methods.
38. Put each SQL value immediately before the method that executes it.
