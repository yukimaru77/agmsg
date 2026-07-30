---
name: __SKILL_NAME__
description: Cross-agent messaging via SQLite. Send messages between Claude Code, Codex, Gemini CLI, and other agents. No daemon, no network, no dependencies beyond bash and sqlite3.
---

Agent messaging command. **IMPORTANT: Always use the provided scripts. NEVER directly read or edit config files, DB, or team data. There is NO register.sh — use join.sh to join a team.**

**Shell requirement:** All agmsg scripts are Bash scripts. Always execute them via `bash`, never via PowerShell or cmd directly. If your default shell is not Bash (e.g. PowerShell on Windows), wrap every command with `bash -lc '...'`. Example: `bash -lc '~/.agents/skills/__SKILL_NAME__/scripts/send.sh myteam alice bob "hello"'`. Always single-quote the `bash -lc` payload; NEVER use a double-quoted wrapper with escaped inner quotes (e.g. `bash -lc "... \"$PWD\" ..."`) — PowerShell parses `\"` as a literal backslash that terminates the string, silently corrupting the command and dropping everything after it. Do NOT construct DB paths manually — the scripts handle path resolution internally. If you need to redirect storage, use `AGMSG_STORAGE_PATH` (the supported override).

## Identity

If you already know your AGENT and TEAMS from a previous `$__SKILL_NAME__` call in this session, skip to **Execute** below.

Otherwise, run: `~/.agents/skills/__SKILL_NAME__/scripts/whoami.sh "$(pwd)" codex`

Four possible outputs:

**A) Single identity:**
`agent=<name> teams=<t1,t2,...> type=codex project=<path>`
→ Remember AGENT and TEAMS, then go to **Execute**.

**B) Multiple identities:**
`multiple=true agents=<n1,n2,...> teams=<t1,t2,...> type=codex project=<path>`
→ Ask the user which agent name to use for this session, then go to **Execute**.

**C) Not in a team:**
`not_joined=true available_teams=<t1,t2,...>` (or `available_teams=none`)
→ Show the user the available teams from the output, then:

  > **First-time setup required.**
  > Joining a team so this agent can send and receive messages.
  > - **Team name**: a group of agents that can message each other (available: <list from output>)
  > - **Agent name**: this agent's identity within the team

  1. Ask: "Enter a team name (joins existing or creates new)"
  2. If the team name given already appears in `available_teams`, run `~/.agents/skills/__SKILL_NAME__/scripts/team.sh <team>` to see the current roster (name, type, project) and note the names already in use. Look for a naming convention already in play (e.g. a shared base name with role/number suffixes like `aggie-cc1`/`aggie-cc2`, or names derived from the team name) and, when one exists, propose 2-3 unused names that extend it; otherwise propose 2-3 short, distinctive identity names (not a bare tool-type label like `codex`/`cc`). Either way, names must not collide with the roster. Then ask: "Enter a name for this agent (suggestions: <name1>, <name2>, <name3> — or type your own)". For a brand-new team, skip the roster check and just ask: "Enter a name for this agent".
  3. **You MUST use join.sh** — run: `~/.agents/skills/__SKILL_NAME__/scripts/join.sh <team> <agent_name> codex "$(pwd)"`
  4. Show the result and explain:

  > **Joined!** You can now use `$__SKILL_NAME__` to check and send messages.
  > - `$__SKILL_NAME__` — check inbox
  > - `$__SKILL_NAME__ send <agent> <message>` — send a message
  > - `$__SKILL_NAME__ team` — list team members
  > - `$__SKILL_NAME__ history` — message history

  5. **REQUIRED — Do NOT skip this step.** Ask the user to pick a delivery mode using exactly this prompt:

     ```
     Choose delivery mode for incoming messages:

      1) monitor — Real-time push (~5s latency)
                   SessionStart hook + Monitor tool streams events.
                   Recommended.

       2) turn    — Check inbox at the end of each assistant turn
                    Stop hook pulls after each response.

      3) both    — monitor primary, turn as fallback
                   Redundant safety net.

      4) off     — No automatic delivery
                   Manual $__SKILL_NAME__ only.

     [1]:
     ```

     - **Wait for the user's answer before proceeding.** Empty input means `1` (monitor).
     - Map the chosen number to a mode and run:
       `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh set <mode> codex "$(pwd)"`
     - Read the `AGMSG-DIRECTIVE` block printed by `delivery.sh` and follow it using Codex's Monitor tools.

  6. Then check inbox for the newly joined team.

**D) Suggestions for reuse:**
`suggest=true agents=<n1,n2,...> teams=<t1,t2,...> type=codex project=<path> available_teams=<t1,t2,...>`
→ No exact registration exists for this project, but there are same-type agent names registered elsewhere.

  1. Show the suggested agent names to the user.
  2. Ask whether to reuse one of those names or choose a new one.
  3. Ask for the team name to join (existing or new).
  4. Run: `~/.agents/skills/__SKILL_NAME__/scripts/join.sh <team> <agent_name> codex "$(pwd)"`
  5. Then continue with the normal post-join flow above.

## Execute

**Only use scripts in `~/.agents/skills/__SKILL_NAME__/scripts/` — do not read or modify files under `teams/` or `db/` directly.**

**Ensure monitor is running first.** Before processing any subcommand below, check whether this session already has an `agmsg inbox stream` Monitor task. If not, and the project's delivery mode is `monitor` or `both` (check via `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh status codex "$(pwd)"`), first run:

- `~/.agents/skills/__SKILL_NAME__/scripts/monitor-command.sh codex "$(pwd)"`

Then invoke Codex's Monitor tool with the printed command, description `agmsg inbox stream`, and persistent mode. Pass the printed command verbatim: it contains a literal session id because Monitor workers may not inherit `$CODEX_THREAD_ID`.

**If no arguments provided (DEFAULT action — always do this when the command is invoked without arguments):**
1. **IMMEDIATELY** run inbox check for each TEAM: `~/.agents/skills/__SKILL_NAME__/scripts/inbox.sh $TEAM $AGENT`
2. Do NOT ask the user what to do — just run the inbox check.
3. If there are messages, read and respond appropriately. To reply:
   `~/.agents/skills/__SKILL_NAME__/scripts/send.sh $TEAM $AGENT <to_agent> "<message>"`

If argument is "history":
1. Run: `~/.agents/skills/__SKILL_NAME__/scripts/history.sh $TEAM $AGENT`

If argument is "team":
1. For each TEAM, run: `~/.agents/skills/__SKILL_NAME__/scripts/team.sh $TEAM`

If argument starts with "send" (e.g. "send misaki check the server"):
1. Parse target agent and message from the arguments
2. Determine which team the target agent belongs to, then run:
   `~/.agents/skills/__SKILL_NAME__/scripts/send.sh $TEAM $AGENT <to_agent> "<message>"`

If argument is "config":
1. Run: `~/.agents/skills/__SKILL_NAME__/scripts/config.sh show`
2. Show the output to the user.

If argument starts with "config set" (e.g. "config set hook.check_interval 30"):
1. Parse key and value from the arguments.
2. Run: `~/.agents/skills/__SKILL_NAME__/scripts/config.sh set <key> <value>`


If argument starts with "actas" followed by an agent name (e.g. "actas alice"):
1. Parse the new role name. If none was given (e.g. bare "actas", or the user asks you to suggest one), run `~/.agents/skills/__SKILL_NAME__/scripts/team.sh <team>` for each TEAM to see the current roster. Look for a naming convention already in play (e.g. a shared base name with role/number suffixes like `aggie-cc1`/`aggie-cc2`, or names derived from the team name) and, when one exists, propose 2-3 unused names that extend it; otherwise propose 2-3 short, distinctive identity names (not a bare tool-type label). Either way, names must not collide with the roster. Ask the user to pick one or type their own before continuing.
2. Run `~/.agents/skills/__SKILL_NAME__/scripts/identities.sh "$(pwd)" codex` to see whether the role is already registered for this (project, type).
3. If the name does not appear in the output, join under the existing team. For a single team, run `~/.agents/skills/__SKILL_NAME__/scripts/join.sh <team> <name> codex "$(pwd)"`. For multiple teams, ask the user which team to join the new role into.
4. Resolve this session's instance id: `AGMSG_SESSION_ID="$(~/.agents/skills/__SKILL_NAME__/scripts/session-id.sh codex "$(pwd)")"`.
5. Pre-flight the exclusive role lock with `~/.agents/skills/__SKILL_NAME__/scripts/actas-claim.sh "$(pwd)" codex <name> "$AGMSG_SESSION_ID"`. If it reports `status=held`, abort without changing Monitor. If it reports `status=ok`, continue.
6. Switch receive to the selected role:
   a. Find any Monitor whose description begins with `agmsg inbox stream` and stop it if present.
   b. Only when delivery mode is `monitor` or `both`, run `~/.agents/skills/__SKILL_NAME__/scripts/monitor-command.sh --session-id "$AGMSG_SESSION_ID" codex "$(pwd)" <name>` and invoke a fresh persistent Monitor with the printed command and description `agmsg inbox stream (acting as <name>)`.
7. Set the session's active FROM to `<name>` for every `send.sh` call until another `actas`.
8. Record this session as the role's resumable seat (best-effort): determine its team, then run `~/.agents/skills/__SKILL_NAME__/scripts/drivers/types/codex/codex-record-session.sh <team> <name>`.
9. Tell the user: "Now acting as `<name>`. Sends use `<name>` as from; receive is restricted to `<name>` only."

If argument starts with "drop" followed by an agent name (e.g. "drop alice"):
1. Parse the role name.
2. Resolve this session's instance id and run `~/.agents/skills/__SKILL_NAME__/scripts/reset.sh "$(pwd)" codex <name> "$AGMSG_SESSION_ID"` to remove the registration and release locks held by this session.
3. If the session's active FROM was `<name>`, clear it. Stop the current agmsg Monitor if present; when delivery mode is `monitor` or `both`, use `monitor-command.sh --session-id "$AGMSG_SESSION_ID" codex "$(pwd)"` to start the default unfiltered Monitor again.
4. Tell the user: "Dropped role `<name>` from this project."

If argument starts with "spawn" (e.g. "spawn claude-code alice", "spawn codex reviewer --window"):
1. Parse `<type>` (must be `claude-code` or `codex`), `<name>`, and any options (`--project`, `--team`, `--window`, `--split h|v`, `--terminal`, `--no-wait`, `--ready-timeout <secs>`).
2. Run: `~/.agents/skills/__SKILL_NAME__/scripts/spawn.sh <type> <name> --project "$(pwd)" [options]`
   - spawn.sh pre-joins `<name>`, then opens a tmux pane/window (when this session is inside tmux) or a new OS terminal, and launches the target CLI with `$__SKILL_NAME__ actas <name>` for Codex or `/__SKILL_NAME__ actas <name>` for Claude Code as its initial prompt.
   - By default it BLOCKS until the new agent's watcher attaches (`status=ready`); `status=timeout` + exit 3 if not ready within `--ready-timeout` (default 90s). Use `--no-wait` for fire-and-forget.
   - It refuses early if `<name>` is already held by another live session, if the target CLI is not installed, or if there is no tmux and no usable terminal (headless).
3. Show the script's output.

If argument starts with "despawn" (e.g. "despawn reviewer", "despawn alice --force"):
1. Parse `<name>` and any options (`--force`, `--timeout <secs>`). `despawn` is the inverse of `spawn` — it tears down a member you previously spawned.
2. Determine which team `<name>` belongs to (as with `send`), then run:
   `~/.agents/skills/__SKILL_NAME__/scripts/despawn.sh <team> $AGENT <name> [--force] [--timeout <secs>]`
   - Default (graceful): sends a `ctrl:despawn` control message to `<name>`. Its watcher drops the role and closes its tmux pane. The command blocks until the lock releases, up to `--timeout` (default 30s), then prints `status=ok`.
   - `--force`: skips the message and tears the member down from the placement recorded at spawn time — kills its tmux pane/window and drops its registration.
3. Show the script's output.

If argument is "mode" (no further args):
1. Run: `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh status codex "$(pwd)"`
2. Show the output to the user.

If argument starts with "mode" followed by a mode name (e.g. "mode monitor"):
1. Parse the mode (one of `monitor`, `turn`, `both`, `off`).
2. Run: `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh set <mode> codex "$(pwd)"`
3. Read the `AGMSG-DIRECTIVE` output and start or stop Codex Monitor as instructed.

If argument is "hook on" (legacy alias):
1. Run: `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh set turn codex "$(pwd)"`
2. Tell the user: "Delivery mode set to 'turn' (legacy hook on behavior)."

If argument is "hook off" (legacy alias):
1. Run: `~/.agents/skills/__SKILL_NAME__/scripts/delivery.sh set off codex "$(pwd)"`
2. Tell the user: "Delivery mode set to 'off'."

If argument is "version":
1. Run: `~/.agents/skills/__SKILL_NAME__/scripts/version.sh`
2. Show the output — the installed version (git-describe provenance recorded at install time).

If argument is "reset":
1. Run: `~/.agents/skills/__SKILL_NAME__/scripts/reset.sh "$(pwd)" codex`
2. Tell the user the result.
