# Scala + React Functional Course Skill

A coding-agent skill that encodes one course's mandatory rules for Scala 3 backends and React TypeScript frontends: 60 numbered compliance rules, backend and frontend pattern references, concrete code examples, and a full-project review checklist. It is designed for course assignments, implementation work, refactors, and compliance audits — not for unrelated Scala or React projects.

The same files work with **DeepSeek Harness (DSH)**, **OpenAI Codex CLI**, and **Claude Code**, because all three discover a skill as a directory containing `SKILL.md` under a skills root.

## What the skill does

- Loads the course's numbered rules only for the side a task touches: rules 1–38 for the backend, 39–60 for the frontend, plus the cross-cutting and interpretation rules.
- Keeps generated Scala and React code inside the course's functional model: Cats Effect `IO` at the boundaries, declarative API messages, public typed table methods, pure React data flow, Tailwind.
- Reviews against the same numbers and reports `Rule / Location / Why / Fix`, distinguishing mandatory failures from optional improvements.
- Refuses to treat "it compiles" or "it looks like the sample" as compliance, and warns which sample patterns must be corrected rather than copied.

## Supported harnesses

| Harness | User root | Project root | Explicit invocation |
|---|---|---|---|
| DeepSeek Harness | `~/.dsh/skills` | `<project>/.dsh/skills` | `/scala-react-functional-course` |
| Codex CLI | `~/.codex/skills` | `<project>/.codex/skills` | `$scala-react-functional-course` |
| Claude Code | `~/.claude/skills` | `<project>/.claude/skills` | `/scala-react-functional-course` |

The skill directory must be named anything as long as it contains `SKILL.md`; the scripts install it as `scala-react-functional-course` to match the declared `name`.

## Install

The install scripts link this repository into a skills root (a junction on Windows, a symlink elsewhere). Because the link points at the repository, edits to the rules take effect immediately; `--copy` copies the files instead and records an install marker so uninstall can find them.

Windows PowerShell:

```powershell
# If your execution policy blocks unsigned scripts, invoke one explicitly:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Harness dsh -Scope user
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Harness dsh -Scope user
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Harness all -Scope project -Project C:\code\course
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Harness dsh -Copy
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
```

POSIX shells:

```sh
./scripts/install.sh --harness dsh --scope user
./scripts/install.sh --harness all --scope project --project ~/code/course
./scripts/install.sh --harness dsh --copy --dry-run
```

Manual install: copy this repository so that `<root>/scala-react-functional-course/SKILL.md` exists, or create a link with the same layout.

Restart the harness or wait for its skill catalog to refresh after installing or removing the link.

## Turn it off

None of the three harnesses has a per-repository "enable this skill" switch: a skill installed under a **user** root is offered in every session of that harness. Choose the scope that matches how often you need it.

1. **Uninstall the link (fastest global off).** `./scripts/uninstall.ps1 -Harness dsh -Scope user` (or `./scripts/uninstall.sh --harness dsh --scope user`). It removes only a link or copied directory that this repository installed; the repository itself is untouched. A linked skill disappears from the next catalog refresh.
2. **Install per project instead of per user (recommended when only some repositories use it).** `-Scope project -Project <course repository>` puts the skill under `<project>/.dsh/skills` (or `.codex`, `.claude`). Repositories without that directory never see it, so there is nothing to disable.
3. **Hide it from the model but keep manual invocation.** Set `disable-model-invocation: true` in the installed copy's `SKILL.md` frontmatter. DSH then leaves it out of the model catalog; `/scala-react-functional-course` still loads it on request. Prefer doing this in an installed copy rather than in this repository, unless you want the behavior for every install.
4. **Codex only, explicit invocation.** Set `policy.allow_implicit_invocation: false` in `agents/openai.yaml` so Codex runs the skill only when you type `$scala-react-functional-course`.

If you later add a copy of the same name to a project root, the project copy wins over the user copy, so a project can pin its own variant.

## Use

- Automatic: a harness loads the skill when a task matches the description ("course project", "Scala", "React", "compliance audit").
- Manual: `/scala-react-functional-course` in DSH or Claude Code, `$scala-react-functional-course` in Codex.
- Inside the skill, the base directory holds the references. `SKILL.md` names which file to load for which task; the review checklist names the rule ranges each check verifies.

Keep the skill scoped: it must not be applied to unrelated Scala or React projects. The description carries that instruction, and the first paragraph of `SKILL.md` repeats it.

## Repository layout

| Path | Purpose |
|---|---|
| `SKILL.md` | Entry point: authority order, reference loading, functional model, workflow, review behavior, rule map. |
| `references/compliance-rules.md` | Authority statement, rule index, cross-cutting rules, lecture interpretation rules, source status. |
| `references/compliance-backend.md` | Authoritative rules 1–38. |
| `references/compliance-frontend.md` | Authoritative rules 39–60. |
| `references/backend-scala.md` | Backend patterns and compliant/noncompliant code examples. |
| `references/frontend-react.md` | Frontend patterns and code examples. |
| `references/review-checklist.md` | Audit procedure, search patterns, verification flows, report format. |
| `agents/openai.yaml` | Codex/OpenAI UI metadata (display name, short description, default prompt). |
| `scripts/install.*`, `scripts/uninstall.*` | Link or copy the skill into a harness root, and remove it. |

## Maintenance

- **The numbered rule files are the source of truth.** `references/compliance-backend.md` and `references/compliance-frontend.md` carry the requirements; keep their wording authoritative and the index in `references/compliance-rules.md` in sync.
- **Rule numbers are global and stable.** Rules stay numbered 1–60 wherever they live; do not renumber when editing a file. New rules append after 60 (or into the matching side file) with the next number.
- **Keep each fact in one place.** Numbered rule text lives in `compliance-backend.md` / `compliance-frontend.md`; the checklist only names the rule numbers and the verification step; `SKILL.md` holds behavior and the map.
- **Keep the description trigger-focused.** DSH renders only the skill name and description in its catalog and truncates the description at 500 characters, so the scope sentence ("Do not apply … to unrelated projects") must stay inside that limit.
- **Bump `metadata.version`** when the rule set or packaging changes.

## Known gaps

- Rule 59 names `docs/` as the documentation folder default because the course requirements do not fix a folder name; update the rule if the course names one.
- The sample projects and the class-note screenshot mentioned in the authority order are not bundled; the sample warnings describe the patterns instead.
- No eval fixtures: the skill has not been tested against a compliant and a noncompliant sample project.

## Provenance

Synthesized from the course's numbered requirements, lecture decks 1–5, the provided backend/frontend and student samples, and the referenced [`Zzzaurak/Scala-course-skills`](https://github.com/Zzzaurak/Scala-course-skills) repository. The current source set did not contain the mentioned class-note screenshot; incorporate it at priority 4 when available, without overriding the rules or decks.

## License

GPL-3.0. See `LICENSE`.
