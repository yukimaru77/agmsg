# Codex Native Monitor Parity Merge Notes

This note records the intent, changed areas, and conflict-resolution rules for the
`codex-claude-monitor-parity` branch. It exists because GitHub Issues are disabled
for `yukimaru77/agmsg`, so the merge notes need to live in the repository.

## Current Branch State

- Branch: `codex-claude-monitor-parity`
- Current HEAD when written: `a57f110 Clarify Codex monitor template wording`
- Base main when written: `61d5e64 feat(grok-build): add opt-in explicit-launch monitor delivery (#236)`
- Local untracked runtime artifact at time of writing: repo-root `run/`
  - Do not commit this unless it is intentionally converted into a test fixture.

## Goal

Codex now has a native Monitor tool, so agmsg should treat Codex like Claude for
default monitor delivery:

- Codex `agmsg monitor` should default to native Monitor.
- Old Codex app-server bridge, shim, and PATH setup should be explicit opt-in
  compatibility paths, not the default explanation or runtime path.
- Docs, tests, and scripts should not say or imply that Codex has no Monitor by
  default.
- Claude-oriented monitor behavior should apply to Codex when the underlying
  tool capability is now equivalent.

## Commits To Preserve

### `37da206 Avoid overwriting shared skill via OpenCode symlink`

What changed:

- `install.sh` no longer overwrites the shared skill at
  `~/.agents/skills/agmsg/SKILL.md` with an OpenCode-specific template when
  installing or updating OpenCode support.
- OpenCode continues to point at the shared skill path through a symlink.
- `tests/test_install.bats` covers this behavior.

Why it matters:

The shared skill is used by Codex. If OpenCode install/update rewrites it with
OpenCode-specific content, Codex can lose the native Monitor instructions.

### `a0c4dcc Use Codex native monitor directives`

What changed:

- Codex session-start and delivery scripts emit native `monitor_start`
  instructions.
- Codex session-end/stop emits native `monitor_stop` instructions.
- `AGMSG_WATCH_READY_STDOUT=1` is used so the monitor-launched watch process
  emits a startup-ready line.
- Legacy bridge/shim code remains available as compatibility, but is not the
  default path.
- Delivery tests were updated around the new default.

Why it matters:

This is the core parity change. If a future merge conflict restores the bridge as
the default Codex path, the feature regresses.

### `a57f110 Clarify Codex monitor template wording`

What changed:

- `scripts/drivers/types/codex/template.md` now tells Codex to call native
  `monitor_start` and `monitor_stop` directly.
- Ambiguous wording that could cause Codex to run `watch.sh` through ordinary
  shell execution was removed.

Why it matters:

The model follows the skill text. The template must clearly say to use native
Monitor tools, not a shell-launched watch loop.

## High-Risk Conflict Areas

### Codex driver and template files

Likely conflict files:

- `scripts/drivers/types/codex/template.md`
- `scripts/drivers/types/codex/_delivery.sh`
- `scripts/drivers/types/codex/_session-start.sh`
- `scripts/drivers/types/codex/type.conf`
- `scripts/drivers/types/codex/codex-monitor.sh`
- `scripts/drivers/types/codex/codex-bridge.js`
- `scripts/drivers/types/codex/codex-shim.sh`
- `scripts/drivers/types/codex/codex-shim-install.sh`

Resolution rule:

Keep Codex native Monitor as the default. Legacy bridge/shim references may stay
only when clearly marked as explicit opt-in compatibility. Do not restore wording
like "Codex has no Monitor" as a current default assumption.

### Delivery/session files

Likely conflict files:

- `scripts/delivery.sh`
- `scripts/session-start.sh`
- `scripts/watch.sh`

Resolution rule:

For Codex monitor mode, preserve native Monitor directives:

- Startup should tell Codex to call `monitor_start`.
- Shutdown should tell Codex to call `monitor_stop`.
- Monitor-launched watch commands should keep `AGMSG_WATCH_READY_STDOUT=1`.

Do not resolve conflicts by falling back to default `TaskList`, `TaskStop`,
app-server-only, PATH-shim-required, or ordinary shell `watch.sh` execution for
the default Codex monitor path.

### Installer files

Likely conflict files:

- `install.sh`
- `tests/test_install.bats`

Resolution rule:

Do not let OpenCode install/update overwrite the shared skill file at
`~/.agents/skills/agmsg/SKILL.md`. OpenCode should continue to use:

```text
~/.config/opencode/skills/agmsg -> ~/.agents/skills/agmsg
```

Observed local installed layout during verification:

```text
~/.agents/skills/agmsg
~/.claude/commands/agmsg.md
~/.config/opencode/skills/agmsg -> ~/.agents/skills/agmsg
```

### Docs and tests

Likely conflict files:

- `README.md`
- `SKILL.md`
- `docs/codex-monitor-beta.md`
- `docs/agent-types.md`
- `docs/design.md`
- `docs/spec/driver-interface.md`
- `tests/test_delivery.bats`
- `tests/test_codex_bridge.bats`
- `tests/test_codex_shim.bats`

Resolution rule:

Docs/tests should describe native Codex Monitor as the default. Bridge, shim,
beta monitor, and PATH explanations are acceptable only when they are clearly
framed as legacy compatibility or explicit opt-in behavior.

## Conflict Audit Search

After resolving future conflicts, run:

```bash
rg -n "Codex has no Monitor|no Monitor|beta bridge|app-server bridge|TaskList|TaskStop|shim|PATH" \
  README.md SKILL.md docs scripts tests
```

Interpret results carefully:

- A legacy/shim mention is acceptable if it is explicitly compatibility-only.
- A default-path statement that says Codex lacks Monitor is a regression.
- `TaskList`/`TaskStop` should not be the Codex native Monitor default path.

## Verification Already Performed

Static and targeted checks performed on this branch:

```bash
bash -n <edited shell scripts>
node --check <edited JS scripts>
git diff --check
npm test
```

Additional targeted checks:

- Codex skill/session-start emits native `monitor_start` instructions.
- Codex session-end emits native `monitor_stop` instructions.
- `watch.sh` emits a ready line when launched with
  `AGMSG_WATCH_READY_STDOUT=1`.

Bats note:

- Bats was not available in the local environment during the original work, so
  full Bats execution was not run there.

## Runtime Verification With cmux

cmux was used to create separate interactive Claude and Codex panes under:

```text
/Users/nonaka/tasks/agmsg
```

Verified identities:

```text
Claude: team=test, name=claude, type=claude-code
Codex:  team=test, name=codex,  type=codex
```

Verified delivery mode for both:

```text
mode: monitor
```

### Busy-state verification

Codex was given a long `/goal` prompt to read files under the repository for
several minutes. While Codex was busy, Claude sent three pings roughly 60 seconds
apart. Codex received all three through Monitor and replied through agmsg without
abandoning the long task.

Recorded agmsg history:

```text
2026-06-26T18:24:19Z claude -> codex progress-ping-1
2026-06-26T18:24:34Z codex  -> claude progress-ping-1 reply
2026-06-26T18:25:24Z claude -> codex progress-ping-2
2026-06-26T18:25:35Z codex  -> claude progress-ping-2 reply
2026-06-26T18:26:28Z claude -> codex progress-ping-3
2026-06-26T18:26:39Z codex  -> claude progress-ping-3 reply
```

### Idle wake verification

After Codex returned to `Goal achieved` / prompt-waiting state, Claude sent one
more message. Codex woke from the Monitor event without manual input and replied
through agmsg.

Recorded agmsg history:

```text
2026-06-26T18:30:04Z claude -> codex idle-wake-1
2026-06-26T18:30:14Z codex  -> claude idle-wake-1 reply
```

## Revalidation Checklist After Future Merges

1. Resolve code conflicts while preserving the rules above.
2. Re-run static checks:

   ```bash
   git diff --check
   npm test
   bash -n scripts/*.sh scripts/drivers/types/codex/*.sh
   node --check scripts/drivers/types/codex/codex-bridge.js
   ```

3. If Bats is available, run targeted tests:

   ```bash
   bats tests/test_install.bats \
     tests/test_delivery.bats \
     tests/test_codex_bridge.bats \
     tests/test_codex_shim.bats
   ```

4. Reinstall/update the local skill:

   ```bash
   ./install.sh --update --cmd agmsg --agent-type codex
   ```

5. Verify installed paths:

   ```bash
   ls -ld ~/.agents/skills/agmsg
   readlink ~/.config/opencode/skills/agmsg
   ls -l ~/.claude/commands/agmsg.md
   ```

6. Do a small cmux smoke test:

   - Start Claude in one pane.
   - Start Codex in another pane.
   - Join/use the same team with different agent names.
   - Set delivery to monitor.
   - Send one Claude -> Codex message while Codex is idle and confirm Codex wakes.
   - Send one Claude -> Codex message while Codex is doing a long task and confirm
     Codex replies before continuing.

## Runtime State Safety

Do not directly edit CC Switch DB or agmsg runtime DB/state files under:

```text
~/.agents/skills/agmsg/db
~/.agents/skills/agmsg/teams
~/.agents/skills/agmsg/run
```

Use agmsg scripts for runtime state changes instead.
