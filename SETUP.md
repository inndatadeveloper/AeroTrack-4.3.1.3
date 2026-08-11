# Running AeroTrack on a Fresh Machine

This covers cloning and running AeroTrack from scratch, including the
gotchas discovered while setting it up the first time.

## Prerequisites

Install these first:

| Tool | Version | Notes |
|---|---|---|
| Git | any recent | |
| JDK | 17 | Confirm with `java -version` |
| Maven | 3.6+ | Confirm with `mvn -version` |
| Docker Desktop | any recent | Includes Docker Compose |

Also budget:
- **~10–15 GB free disk** (Maven dependencies + Docker images + build output)
- **~20–30 minutes** for the first full build (downloads a lot; later builds are much faster since dependencies get cached in `~/.m2`)

---

## 1. Clone the repo

```bash
git clone https://github.com/inndatadeveloper/AeroTrack-4.3.1.3.git
cd AeroTrack-4.3.1.3
```

If working from a different branch than the repo's default, check out the right one:
```bash
git branch -a          # see available branches
git checkout main      # or whichever branch has your latest work
```

---

## 2. Full build (first time on this machine)

Since there's no `~/.m2` cache yet and no `application/target/*.jar` built,
do a **full** build the first time — not the scoped `-pl ui-ngx,application`
build used during iterative development:

```bash
mvn clean install -DskipTests
```

**This will likely take 15–30 minutes** the first time. Grab a coffee.

### If it fails on a license-header check

You'll see something like:
```
[ERROR] Failed to execute goal com.mycila:license-maven-plugin:3.0:check (default) on project thingsboard: Some files do not have the expected license header
```

This project enforces an Apache license header on every file. If any local/uncommitted
file lacks the header (common with new scripts or tooling-generated files),
the build fails at the very first module before anything else runs. Check
which file(s) it's complaining about in the `[WARNING] Missing header in: ...`
lines just above the error, and either:
- Add the standard header (see `license-header-template.txt` in the repo root), or
- Remove the file if it's not meant to be tracked (e.g. editor-generated
  scratch files under `.github/modernize/` have shown up before from a
  VS Code extension — safe to delete if you see this).

---

## 3. Deploy with Docker

```bash
cd docker-deployment
docker compose build --no-cache
docker compose up -d
```

Watch the logs for the first run — it should perform a **fresh install**
(creates the database schema, seeds default settings):
```bash
docker logs -f aerotrack-app
```

Look for `Installation finished successfully!` followed by the server
starting up. First install takes a minute or two.

### Common issues

- **Port already in use / "address already allocated"**: another container
  (maybe from a previous test) is holding port 8080, 1883, or 5683. Check with
  `docker ps -a` and stop/remove the conflicting container.
- **macOS `sed` errors**: macOS's built-in `sed` needs `sed -i ''` (with an
  empty string argument) for in-place edits, unlike Linux's `sed -i`. If
  following any troubleshooting steps that assume Linux, adjust accordingly.
- **Windows users**: run these commands in **Git Bash**, not PowerShell —
  PowerShell doesn't understand bash syntax and will silently do the wrong
  thing (e.g. open scripts in Notepad instead of running them).

---

## 4. First login

Once the server is up, open **http://localhost:8080** and log in with:

```
Username: sysadmin@aerotrack.io
Password: sysadmin
```

**Change this password immediately** if this is anything beyond a local dev
environment — it's a well-known default.

---

## 5. Rebuilding after making changes

For day-to-day changes to the frontend (`ui-ngx`) or backend
(`application`), you don't need a full rebuild — scope it to just the
affected modules and their dependencies for a much faster cycle:

```bash
mvn -pl ui-ngx,application -am install -DskipTests
```

Then redeploy:
```bash
cd docker-deployment
docker compose down
docker compose build --no-cache
docker compose up -d
```

Note: `docker compose down` (without `-v`) preserves your database volume,
so existing data/settings survive a redeploy. Only use `docker compose down -v`
if you deliberately want to wipe the database and trigger a fresh install
(e.g. to verify a source-level default actually takes effect on a clean install).

---

## 6. Where things live

- `application/` — Java backend (Spring Boot)
- `ui-ngx/` — Angular frontend
- `dao/` — database access layer
- `docker-deployment/` — Dockerfile, docker-compose.yml, entrypoint script for
  running the built jar in containers
- `application/src/main/resources/thingsboard.yml` — main backend config
  (mail server, mobile app links, update-check settings, etc.)
- `ui-ngx/src/assets/dashboard/sys_admin_home_page.json` — the Home page
  dashboard layout (Functions widget, Get Started widget, etc.) — this is
  static JSON, not a compiled Angular component, and only gets loaded into
  the database on a **fresh install** (changes here won't affect an
  already-installed database without either a DB update or a full re-install)
