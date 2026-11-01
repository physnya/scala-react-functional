# Scala backend patterns

Read this file for backend design, implementation, refactoring, or review. The authoritative numbered rules for this side are 1–38 in `compliance-backend.md`; cross-cutting and lecture interpretation rules are in `compliance-rules.md`.

## Required project shape

```text
src/main/scala/
  services/
    system/
      api/
      objects/
      routes/
      tables/
      utils/
    users/
      api/
      objects/
        apiTypes/
      routes/
      tables/
        user/
          UserTable.scala
          UserTableInitializer.scala
      utils/
    books/
      api/
      objects/
        apiTypes/
      routes/
      tables/
        book/
          BookTable.scala
          BookTableInitializer.scala
      utils/
```

Use only needed directories. `services/system/` owns infrastructure; it must not become an unowned dumping ground.

## Domain values and serialization

Use a distinct type for a distinct business concept. Keep the representation small and immutable.

```scala
package services.books.objects

import io.circe.{Decoder, Encoder}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}

final case class BookId(value: String)

object BookId:
  given Encoder[BookId] = deriveEncoder[BookId]
  given Decoder[BookId] = deriveDecoder[BookId]
```

Model finite states with an enum and centralize conversion in the companion.

```scala
package services.books.objects

import io.circe.{Decoder, Encoder}

enum BookInventoryStatus:
  case Available
  case Borrowed

object BookInventoryStatus:
  def toString(status: BookInventoryStatus): String =
    status match
      case BookInventoryStatus.Available => "available"
      case BookInventoryStatus.Borrowed => "borrowed"

  def fromString(value: String): Either[String, BookInventoryStatus] =
    value.trim.toLowerCase match
      case "available" => Right(BookInventoryStatus.Available)
      case "borrowed" => Right(BookInventoryStatus.Borrowed)
      case other => Left(s"Unsupported BookInventoryStatus value: $other")

  given Encoder[BookInventoryStatus] = Encoder.encodeString.contramap(toString)
  given Decoder[BookInventoryStatus] = Decoder.decodeString.emap(fromString)
```

Do not add database mapping or business workflows to these companions.

## API messages

An API message exposes one business operation and one effect plan. Keep orchestration visible.

```scala
package services.books.api

import cats.effect.IO
import services.books.objects.{BookId, BookRecord, BookTitle}
import services.books.tables.book.BookTable
import services.users.api.RequireAdminUserMessage
import services.users.objects.UserId
import services.system.api.APIMessage

import java.sql.Connection

final case class RenameBookMessage(
  userId: UserId,
  bookId: BookId,
  title: BookTitle
) extends APIMessage[BookRecord]:
  override def plan(connection: Connection): IO[BookRecord] =
    for
      _ <- RequireAdminUserMessage(userId).plan(connection)
      book <- BookTable.rename(connection, bookId, title)
    yield book
```

The `for` block is a declarative composition of `IO` values. It does not mutate state or execute an imperative loop.

Use `NoRequestMessage[Response]` only when the operation has no business input. Use `APIWithTokenMessage[Response]` only when the router must convert an external token into a trusted internal identity. Do not create empty request objects.

## Public table operations with private SQL

Every public table method owns binding, execution, resource lifetime, and row mapping. Use `Resource` instead of `try`/`finally`.

```scala
package services.books.tables.book

import cats.effect.{IO, Resource}
import cats.syntax.all.*
import services.books.objects.{BookId, BookRecord}

import java.sql.{Connection, PreparedStatement, ResultSet}

object BookTable:
  private val findByIdSql: String =
    """
      |select id, title
      |from books
      |where id = ?
      |""".stripMargin

  def findById(connection: Connection, id: BookId): IO[Option[BookRecord]] =
    statement(connection, findByIdSql).use { preparedStatement =>
      IO.blocking(preparedStatement.setString(1, id.value)) *>
        resultSet(preparedStatement).use(readOptional)
    }

  private def statement(connection: Connection, sql: String): Resource[IO, PreparedStatement] =
    Resource.fromAutoCloseable(IO.blocking(connection.prepareStatement(sql)))

  private def resultSet(statement: PreparedStatement): Resource[IO, ResultSet] =
    Resource.fromAutoCloseable(IO.blocking(statement.executeQuery()))

  private def readOptional(rows: ResultSet): IO[Option[BookRecord]] =
    IO.blocking(rows.next()).flatMap {
      case true => readBook(rows).map(Some(_))
      case false => IO.pure(None)
    }

  private def readBook(rows: ResultSet): IO[BookRecord] =
    IO.blocking {
      BookRecord(
        id = BookId(rows.getString("id")),
        title = rows.getString("title")
      )
    }
```

The SQL value is private and immediately precedes its public operation. Generic resource helpers remain private within the table object. Never expose a method that accepts arbitrary SQL.

For multiple rows, use recursion inside the delayed boundary rather than a mutable builder or loop:

```scala
private def readBooks(rows: ResultSet): IO[List[BookRecord]] =
  def readRemaining(accumulated: List[BookRecord]): IO[List[BookRecord]] =
    IO.blocking(rows.next()).flatMap {
      case true =>
        readBook(rows).flatMap(book => readRemaining(book :: accumulated))
      case false =>
        IO.pure(accumulated.reverse)
    }

  readRemaining(List.empty)
```

## Service-local utilities

Place only reusable service-internal logic in `utils/`. Expose functions with package-qualified privacy:

```scala
package services.books.utils

import services.books.objects.BookRecord

private[books] def normalizedTitle(book: BookRecord): String =
  book.title.trim.toLowerCase
```

Do not use a utility to hide the main API sequence. Do not make it public merely because another service wants the capability; expose an API message or table operation instead.

## Routes and trust

Each service has one `XXRoutes` registration list. The top router concatenates lists. Registration derives names from message types.

Token-protected requests follow this boundary:

```text
frontend payload with userToken
  -> router validates token through users ownership
  -> router obtains trusted UserId
  -> router constructs backend message
  -> message.plan(connection)
```

Never deserialize an untrusted frontend `userId` directly into an authenticated business message.

## Effect discipline

- Wrap JDBC calls, clocks, UUID creation, filesystem work, and network work in `IO` at the owning boundary.
- Compose effects with `map`, `flatMap`, `*>`, `traverse`, or an `IO` comprehension.
- Keep pure validation as a pure function returning a typed value such as `Either[DomainError, ValidatedValue]`, then lift it once at the boundary.
- Do not call `unsafeRunSync`, `unsafeToFuture`, or another runtime inside APIs, tables, utilities, or objects.
- Do not conceal side effects in a method that returns a plain value.
- Keep transaction ownership visible. Reuse the connection passed to `plan` and public table methods so one business operation can remain in one transaction.

## Sample-code warning

The supplied backend sample is useful for API-message orchestration, routes, objects, and table ownership, but it is not authoritative. Known patterns that must be corrected rather than copied include top-level `system/` ownership, service-private table methods where the rules require public access, JDBC `try`/`finally`, mutable list builders, `while` iteration, time/UUID generation hidden inside table operations, and helper objects that do not use the required `private[service] def` utility form.
