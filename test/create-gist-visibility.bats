#!/usr/bin/env bats
#
# gh-gist-collaboration: new Gists are secret unless --public is asked for,
# and an unrecognized flag fails rather than publishing.

SCRIPT="$BATS_TEST_DIRNAME/../han-github/skills/gh-gist-collaboration/scripts/create-gist-from-dir.sh"

setup() {
  SHARED="$BATS_TEST_TMPDIR/shared"
  mkdir -p "$SHARED" "$BATS_TEST_TMPDIR/bin"
  : > "$SHARED/notes.md"

  # Stub gh so nothing is created; it echoes a URL and records its arguments.
  cat > "$BATS_TEST_TMPDIR/bin/gh" <<'STUB'
#!/bin/sh
echo "$*" > "$GH_ARGS_FILE"
echo "https://gist.github.com/fake123"
STUB
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"

  export GH_ARGS_FILE="$BATS_TEST_TMPDIR/gh-args"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "defaults to a secret Gist when no visibility flag is given" {
  run "$SCRIPT" "$SHARED" "[han] topaz-fit"
  [ "$status" -eq 0 ]
  [[ "$(cat "$GH_ARGS_FILE")" == *"--secret"* ]]
  [[ "$(cat "$GH_ARGS_FILE")" != *"--public"* ]]
}

@test "creates a public Gist only when --public is passed" {
  run "$SCRIPT" "$SHARED" "[han] topaz-fit" --public
  [ "$status" -eq 0 ]
  [[ "$(cat "$GH_ARGS_FILE")" == *"--public"* ]]
  [[ "$(cat "$GH_ARGS_FILE")" != *"--secret"* ]]
}

@test "accepts an explicit --secret" {
  run "$SCRIPT" "$SHARED" "[han] topaz-fit" --secret
  [ "$status" -eq 0 ]
  [[ "$(cat "$GH_ARGS_FILE")" == *"--secret"* ]]
}

@test "rejects an unknown flag instead of creating anything" {
  run "$SCRIPT" "$SHARED" "[han] topaz-fit" --publik
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown flag"* ]]
  [ ! -e "$GH_ARGS_FILE" ]
}
