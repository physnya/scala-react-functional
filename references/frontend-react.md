# React frontend patterns

Read this file for frontend design, implementation, refactoring, or review. The authoritative numbered rules remain in `compliance-rules.md`.

## Functional React model

Treat the view as a function of immutable data:

```text
user action
  -> update core state immutably
  -> derive display data with pure functions
  -> render function components
```

Use function components only. Do not use class components, mutable module state, object instances that own evolving domain state, direct DOM mutation, imperative loops, or in-place array/object mutation.

Keep three data categories distinct:

- Constants do not change over the application's lifetime.
- Core state changes because of users or external events and is held in React hooks or a narrowly scoped Zustand store.
- Display data is derived from constants and core state. Compute it with pure functions or `useMemo` when memoization is justified; do not mirror it into extra state.

Effects belong in API infrastructure, event handlers, or `useEffect` when synchronization with an external system is required. Do not use `useEffect` merely to calculate display data.

## Page organization

```text
pages/
  BookList/
    index.tsx
    hooks/
      useBookList.ts
    objects/
      BookListState.ts
    functions/
      filterBooks.ts
    components/
      BookToolbar.tsx
      BookTable.tsx
```

The page entry exposes the business skeleton:

```tsx
import { BookTable } from './components/BookTable'
import { BookToolbar } from './components/BookToolbar'
import { useBookList } from './hooks/useBookList'

export default function BookList() {
  const page = useBookList()

  return (
    <main className="mx-auto min-h-screen max-w-7xl space-y-6 px-6 py-10">
      <BookToolbar page={page} />
      <BookTable page={page} />
    </main>
  )
}
```

Keep a simple page or region flat. Add nested folders only when they reduce lookup cost.

## Pure display calculations

Move reusable calculations out of JSX and make all inputs explicit.

```ts
import type { BookCatalogRecord } from '../objects/BookCatalogRecord'

export function filterBooks(
  books: readonly BookCatalogRecord[],
  keyword: string,
): readonly BookCatalogRecord[] {
  const normalizedKeyword = keyword.trim().toLowerCase()

  return normalizedKeyword.length === 0
    ? books
    : books.filter((book) =>
        [book.title, book.author, book.isbn]
          .join(' ')
          .toLowerCase()
          .includes(normalizedKeyword),
      )
}
```

Use `map`, `filter`, `flatMap`, and `reduce` to transform collections without mutation. Use exhaustive branching for closed states.

```ts
export type BookListPageState =
  | { readonly status: 'loading' }
  | { readonly status: 'ready'; readonly books: readonly BookCatalogRecord[] }
  | { readonly status: 'empty' }
  | { readonly status: 'error'; readonly message: string }
```

Do not introduce a large union for a small form whose local pending and error state remains unambiguous.

## Zustand

Use Zustand only for core state shared across pages. Keep the store private and export narrow, clearly named accessors.

```ts
import { useStore } from 'zustand'
import { createStore } from 'zustand/vanilla'

import type { UserProfile } from '@/objects/users/UserProfile'

type CurrentUserState = {
  readonly currentUser: UserProfile | null
}

const currentUserStore = createStore<CurrentUserState>(() => ({
  currentUser: null,
}))

export function getCurrentUserSnap(): UserProfile | null {
  return currentUserStore.getState().currentUser
}

export function useCurrentUser(): UserProfile | null {
  return useStore(currentUserStore, (state) => state.currentUser)
}

export function setCurrentUser(currentUser: UserProfile | null): void {
  currentUserStore.setState({ currentUser })
}
```

- Pure functions do not call `useXXX`; accept data as arguments.
- Components subscribe with `useXXX` when rendering data that must update.
- Use `getXXXSnap` only when a non-rendering boundary needs the current snapshot.
- Do not put one-time navigation input or local UI state in a global store.

## Frontend API correspondence

Organize callers by backend service and derive the route name centrally. Each frontend-facing backend message has one simple caller with explicit fields and `send()`.

```ts
import type { BookId } from '@/objects/books/BookId'
import type { BookRecord } from '@/objects/books/BookRecord'
import { APIMessage } from '@/system/api/APIMessage'
import { sendAPI } from '@/system/api/sendAPI'

export class GetBookAPI extends APIMessage<BookRecord> {
  declare readonly responseType: BookRecord
  readonly bookId: BookId

  constructor(bookId: BookId) {
    super()
    this.bookId = bookId
  }

  send(): Promise<BookRecord> {
    return sendAPI<BookRecord>(this)
  }
}
```

Generic token attachment, name derivation, request transport, and response handling live in shared API infrastructure. The frontend sends a token where required; the router converts it to a trusted identity. Never send a self-asserted `userId` as authentication.

Rule 52 intentionally uses a small immutable class for an API caller. Treat it as a typed transport boundary, not as permission to introduce stateful object-oriented domain models or class components.

## Styling and shared components

- Use Tailwind classes. Add custom CSS only for a requirement that Tailwind cannot reasonably express, and keep the exception small and documented.
- Put broadly reused primitives under `components/ui/`.
- Keep page-specific cards, panels, dialogs, rows, and toolbars beside their page even if they use shared UI primitives.
- Remove unused starter assets, libraries, stylesheets, and template folders.

## Cross-page data

Choose the smallest correct boundary:

- Persistent core state shared across pages: private Zustand store.
- Input for one navigation: route parameter, search parameter, or router location state.
- Data owned by the destination: load it from its identifier rather than copying a stale object across pages.

## Sample-code warning

The supplied frontend sample is useful for page-local folders, hooks, API correspondence, Tailwind, and function components, but it is not automatically compliant. Audit local boolean state combinations, imperative `try`/`catch` workflows, missing `send()` methods on API classes, raw string identifiers, display calculations inside JSX, and any API-name mismatch before reusing a pattern.
