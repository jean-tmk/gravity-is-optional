# Gravity Is Optional

> A browser physics office where “down” is only a policy setting.

**Live exhibit:** https://jean-tmk.github.io/gravity-is-optional/

## What it is

The exhibit turns a familiar physical constant into administrative software. Visitors can reassign gravity, test approved alternatives to falling normally, and complete field assignments while an unnecessarily serious relational database records how reality is supposed to behave.

## What a visitor can do

1. Choose one of eight gravity directions or microgravity.
2. Adjust field strength and drag objects before releasing them.
3. Apply an approved policy from the alternatives cabinet.
4. Complete docking, orbit, and sideways-rain missions.
5. Toggle sound, pause time, create gusts, or reset the field.

## How it works

- SQL is the authoritative rule system: policies, transitions, objects, missions, sessions, progress, triggers, telemetry, integrity views, exports, and tests.
- JavaScript runs the browser-safe physics adapter with Canvas rendering, collision audio, drag controls, missions, and policy UI.
- Illustrated object assets keep the matter legible at small sizes.
- Additional languages implement focused audits, solvers, exporters, and policy models while SQL remains the majority.

## Repository map

| Path | What it does |
|---|---|
| `.gitattributes` | GitHub Linguist classification rules for the documented language composition. |
| `.github/workflows/pages.yml` | GitHub Actions workflow that validates, builds, and/or deploys the exhibit. |
| `gravity.css` | A focused style layer for this named area of the experience. |
| `gravity.js` | Browser/application source for the behavior named by this file. |
| `gravity_engine.sql` | Relational schema, query, trigger, view, seed, or validation source. |
| `index.html` | The deployable HTML shell: metadata, accessible structure, controls, and script/style entry points. |
| `sql/gravity_audit.sql` | Relational schema, query, trigger, view, seed, or validation source. |
| `assets/objects/` | 6 production illustration/icon files loaded by the live interface. |
| `polyglot/` | 14 isolated language-atlas files plus the majority registry and manifest; these never load in the visible frontend. |

## Languages and why they are here

Percentages below are calculated from the byte counts currently returned by GitHub Linguist. Tiny language-atlas modules are intentionally isolated from the production frontend.

| Language | GitHub | Role |
|---|---:|---|
| SQL | 72.6% | the majority policy, state, telemetry, trigger, and validation engine |
| HTML | 9.7% | semantic orientation-office shell |
| Ada | 2.1% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| C | 1.7% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| COBOL | 1.5% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| Solidity | 1.5% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| Prolog | 1.4% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| Groovy | 1.4% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| Fortran | 1.3% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| PowerShell | 1.3% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| PHP | 1.2% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| Cuda | 1.2% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| D | 1.2% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| Objective-C | 1.1% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |
| Pascal | 0.9% | an isolated language-atlas adapter used to broaden the comparative polyglot collection without changing the exhibit UI |

### About the language atlas

Where present, `polyglot/language-atlas.json` is the machine-readable index of the languages assigned to this repository. `polyglot/languages/` contains one small, independent signature module per assignment, and `polyglot/majority/` contains the larger registry that preserves the intended majority language. These files are documentation and comparative code specimens: the live site does not download or execute them.

## Local development

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000` unless the framework development server prints a different local address.

## Privacy and access

- No sign-in is required.
- No API key is required for the live exhibit.
- No visitor text is sent to an AI service.
- Any saved progress stays in local browser storage unless the README explicitly describes an optional external architecture.
- Sound begins only after a user gesture where browser autoplay rules require it.

## Deployment

The public version is a static GitHub Pages deployment. The workflow in `.github/workflows/` is the source of truth for its exact build and publish steps. The favicon is stored with the deployed app so browser tabs and bookmarks use the project’s own mark.
