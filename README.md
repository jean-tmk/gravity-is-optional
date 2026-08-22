# Gravity Is Optional

An interactive orientation office where the browser stops treating “down” as a fixed requirement.

Visitors can redirect gravity in eight directions, change field strength, drag matter, release gusts, freeze time, shuffle the lost-and-found, activate stored gravity policies, and complete three different field assignments.

## Why SQL

`gravity_engine.sql` is the real rule system rather than decorative filler. It defines:

- gravity policies and allowed transitions;
- object sets, dimensions, masses, restitution, and archival notes;
- missions and completion targets;
- field messages and sound parameters;
- session, object-state, event, and progress models;
- triggers for docking, mission completion, policy changes, and state validation;
- JSON export views used by the static browser adapter; and
- thirty relational integrity tests.

The deployed GitHub Pages experience uses a compiled browser-safe subset of that database, so it requires no server, account, API key, or external service.

## Run locally

Open `index.html` in a browser. To validate the SQL engine with Python’s built-in SQLite:

```bash
python3 -c "import sqlite3,pathlib; db=sqlite3.connect(':memory:'); db.executescript(pathlib.Path('gravity_engine.sql').read_text()); print(db.execute('select * from build_integrity_report').fetchone())"
```

Every value should be `1`.
