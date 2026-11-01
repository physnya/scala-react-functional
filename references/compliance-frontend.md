# Frontend compliance rules (39–60)

Authoritative numbered requirements for frontend work, split from `compliance-rules.md` without changing their numbers. Read `compliance-rules.md` first for the authority order, the cross-cutting rules, and the lecture interpretation rules.

## Frontend ownership and pages

39. The shared frontend `components/` folder contains only UI primitives reused broadly, normally under `components/ui/`. Page-specific components stay with their page.
40. Keep a page's components, hooks, stores, functions, and objects in that page folder when only that page uses them.
41. Split complex pages by meaningful, user-visible business regions rather than arbitrary visual fragments. Major regions should have clear component names.
42. Use page-level `hooks/`, `objects/`, and `functions/` for state, types, and pure calculations shared by multiple regions on that page. Do not bury shared page logic inside one child component.
43. For a genuinely complex page, use a stable page-level shape: `index.tsx` for the skeleton, `hooks/` for shared coordination, `objects/` for page data, `functions/` for pure logic, and `components/` for visible regions. Recurse inside a complex region only when its own complexity requires it.
44. Keep a complex page's `index.tsx` as the visible high-level skeleton. Move detailed UI, local state logic, stores, and helpers nearby. The entry should reveal the page's main regions.
45. Do not hide the main business structure behind a vague layout wrapper. A reader opening `index.tsx` should immediately see the major regions.
46. Recursively split a region only when it has collaborating submodules or enough internal state to make one file hard to read. Keep a simple region as one `.tsx` file.
47. Modularity must reduce lookup cost. Do not create folders and components for formal symmetry when a flat file is clearer.

## Frontend API, types, style, and state

48. Organize frontend API folders by backend service wherever practical.
49. A frontend-facing backend API message normally has a corresponding frontend API file or class. Backend-only messages need none. Platform-specific trust conversion may cause an intentional difference, which should remain explainable.
50. Put generic frontend API infrastructure outside service folders: token storage, API-name calculation, sending, API bases, and shared request/response handling.
51. Split large frontend API utilities by real responsibility. Do not let one utility become a hidden framework.
52. Define each frontend API in a simple class with explicit input fields and a `send(): Promise<Response>` method. Keep each caller concrete and inspectable.
53. Derive frontend API names through one shared function. Do not redefine `apiName` in every API class.
54. Remove unused scaffold directories, assets, and libraries such as obsolete `app`, `assets`, or `lib` content when nothing references them.
55. Use Tailwind as the declared styling system. Avoid custom CSS and CSS-oriented utilities unless genuinely necessary. Remove infrastructure that conflicts with Tailwind-only styling.
56. Prefer clear folder names. Use `utils` for utilities instead of vague names such as `internal` unless the project gives that term a precise architectural meaning.
57. Put page-shared objects in a clear location such as `pages/objects`. Paths must communicate whether an object is global, service-specific, or page-specific.
58. Prefer clear, direct TypeScript. Strong typing should improve safety or maintenance, not create unnecessary abstraction.
59. Keep generated reports, PDFs, architecture explanations, and conversation histories in the course's documentation folder (normally `docs/`), never mixed into backend or frontend source directories.
60. Explicitly model complex page states such as loading, ready, empty, error, and relevant operation states. A simple independent form may use small local states when the possible combinations stay clear. Do not introduce a large state union without actual complexity.
