#!/bin/sh
[ -n "$HAN_GIST_SHELL" ] || exec env HAN_GIST_SHELL=1 "${SHELL:-bash}" "$0" "$@"
set -euo pipefail

# Usage: install-stop-hook.sh [<project-root>]
#
# Installs the session-end Gist push as personal, project-local config:
#   - the script goes to ~/.claude/scripts/han-gist-auto-push.sh, outside any
#     repository, so nothing untracked appears in the project
#   - the Stop hook is registered in <root>/.claude/settings.local.json, which
#     is gitignored by convention, so teammates are unaffected
#
# Idempotent: re-running refreshes the script and leaves an already-registered
# hook, and every other setting in the file, alone. <project-root> defaults to
# the current directory.
#
# Note: the installed script lives outside chezmoi's source directory, so it
# does not follow you to other machines. Re-run this on each machine.

ROOT="${1:-.}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET="$HOME/.claude/scripts/han-gist-auto-push.sh"
SETTINGS="$ROOT/.claude/settings.local.json"
COMMAND="bash $TARGET"

mkdir -p "$HOME/.claude/scripts" "$ROOT/.claude"
cp "$SCRIPT_DIR/auto-push-gists.sh" "$TARGET"
chmod +x "$TARGET"

ruby -r json -e '
  path, command = ARGV
  settings = File.exist?(path) ? JSON.parse(File.read(path)) : {}
  stop = ((settings["hooks"] ||= {})["Stop"] ||= [])
  if stop.any? { |m| (m["hooks"] || []).any? { |h| h["command"] == command } }
    puts "Stop hook already registered in #{path}."
  else
    stop << { "matcher" => "", "hooks" => [{ "type" => "command", "command" => command }] }
    File.write(path, JSON.pretty_generate(settings) + "\n")
    puts "Stop hook registered in #{path}."
  end
' "$SETTINGS" "$COMMAND"
