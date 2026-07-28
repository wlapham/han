#!/usr/bin/env bats
#
# gh-gist-collaboration: the Stop-hook installer merges into settings.local.json
# without clobbering existing settings, and re-running adds no duplicate.

SCRIPT="$BATS_TEST_DIRNAME/../han-github/skills/gh-gist-collaboration/scripts/install-stop-hook.sh"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  ROOT="$BATS_TEST_TMPDIR/proj"
  SETTINGS="$ROOT/.claude/settings.local.json"
  mkdir -p "$HOME" "$ROOT"
}

@test "installs the script outside the project and registers the hook" {
  run "$SCRIPT" "$ROOT"
  [ "$status" -eq 0 ]
  [ -x "$HOME/.claude/scripts/han-gist-auto-push.sh" ]
  [ ! -e "$ROOT/.claude/scripts" ]
  run ruby -r json -e 'puts JSON.parse(File.read(ARGV[0]))["hooks"]["Stop"].length' "$SETTINGS"
  [ "$output" = "1" ]
}

@test "re-running preserves existing settings and adds no duplicate hook" {
  mkdir -p "$ROOT/.claude"
  echo '{"model": "opus"}' > "$SETTINGS"
  "$SCRIPT" "$ROOT"
  "$SCRIPT" "$ROOT"
  run ruby -r json -e '
    s = JSON.parse(File.read(ARGV[0]))
    puts s["hooks"]["Stop"].length
    puts s["model"]
  ' "$SETTINGS"
  [ "${lines[0]}" = "1" ]
  [ "${lines[1]}" = "opus" ]
}
