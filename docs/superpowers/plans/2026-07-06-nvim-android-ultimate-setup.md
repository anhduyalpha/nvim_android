# Neovim Android Ultimate Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish this repo as a reproducible Android/Termux Neovim setup and push it to GitHub.

**Architecture:** Keep the existing LazyVim Android config. Add only missing onboarding: a Termux installer/check script and a README that explains install, verify, backup, and recovery. Verify existing Lua tests and performance check before commit/push.

**Tech Stack:** Neovim Lua API, LazyVim, Termux `pkg`, Bash, git.

## Global Constraints

- No new Neovim plugin dependencies.
- Reuse existing `check_performance.sh`, `backup_recovery.sh`, tests, and config modules.
- Keep installer non-destructive: move existing `~/.config/nvim` aside before linking.
- Push finished work to `origin`.

---

### Task 1: Android Onboarding

**Files:**
- Create: `README.md`
- Create: `scripts/termux-setup.sh`
- Modify: none
- Test: `bash -n scripts/termux-setup.sh`

**Interfaces:**
- Consumes: repo root, `check_performance.sh`, `backup_recovery.sh`
- Produces: executable `scripts/termux-setup.sh`

- [ ] **Step 1: Add installer script**

Create `scripts/termux-setup.sh` with a safe Termux dependency install, symlink to `~/.config/nvim`, Lazy sync, and performance check.

- [ ] **Step 2: Add README**

Create `README.md` with Android install, verify, backup, recovery, and update commands.

- [ ] **Step 3: Syntax check**

Run: `bash -n scripts/termux-setup.sh`
Expected: no output.

### Task 2: Verification

**Files:**
- Modify only if tests fail.
- Test: `tests/*.lua`, `check_performance.sh`

**Interfaces:**
- Consumes: existing Lua tests and performance checker
- Produces: passing verification evidence

- [ ] **Step 1: Run Lua tests**

Run each `tests/*.lua` through `nvim --headless -c "luafile <file>" -c "qa"`.
Expected: every test exits 0.

- [ ] **Step 2: Run performance check**

Run: `./check_performance.sh`
Expected: exits 0 and writes `performance_report.txt`.

- [ ] **Step 3: Fix only real failures**

Patch smallest shared root cause. Re-run failed command.

### Task 3: Commit and Push

**Files:**
- Commit: plan, README, scripts, and any fixes.

**Interfaces:**
- Consumes: verified working tree
- Produces: pushed branch on GitHub

- [ ] **Step 1: Review diff**

Run: `git diff --check && git status --short`.
Expected: no whitespace errors; only intended files changed.

- [ ] **Step 2: Commit**

Commit with message `docs(android): add reproducible Termux setup`.

- [ ] **Step 3: Push**

Run: `git branch --show-current`.
Expected: `ultimate-android-setup`.

Run: `git push -u origin ultimate-android-setup`.
Expected: branch pushed to GitHub.

## Self-Review

- Spec coverage: onboarding, verification, commit, push covered.
- Placeholder scan: no TBD/TODO/implement-later instructions.
- Type consistency: Bash and repo command names match existing files.
