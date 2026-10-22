#!/usr/bin/env bats
#
# gh-gist-collaboration: new Gists are secret unless --public is asked for,
# and an unrecognized flag fails rather than publishing.
#
# `gh gist create` is secret by default and accepts only -p/--public, so the
# stub below rejects every other flag the way the real CLI does. A stub that
# accepted anything would pass while the script forwarded a flag gh refuses.

SCRIPT="$BATS_TEST_DIRNAME/../han-github/skills/gh-gist-collaboration/scripts/create-gist-from-dir.sh"

setup() {
  SHARED="$BATS_TEST_TMPDIR/shared"
  mkdir -p "$SHARED" "$BATS_TEST_TMPDIR/bin"
  : > "$SHARED/notes.md"

  cat > "$BATS_TEST_TMPDIR/bin/gh" <<'STUB'
#!/bin/sh
# Mirrors the flags `gh gist create` actually accepts.
[ "$1" = "gist" ] && [ "$2" = "create" ] || { echo "unexpected: $*" >&2; exit 1; }
shift 2
while [ $# -gt 0 ]; do
  case "$1" in
    -d|--desc|-f|--filename) shift 2 ;;
    -p|--public|-w|--web) shift ;;
    -*) echo "unknown flag: $1" >&2; exit 1 ;;
    *) shift ;;
  esac
done
echo "$*" > "$GH_ARGS_FILE"
echo "https://gist.github.com/fake123"
STUB
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"

  export GH_ARGS_FILE="$BATS_TEST_TMPDIR/gh-args"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

# Records every argument the script handed to gh, so a test can assert on a
# flag that was never passed as well as one that was.
gh_invocation() {
  cat > "$BATS_TEST_TMPDIR/bin/gh" <<'STUB'
#!/bin/sh
echo "$*" > "$GH_ARGS_FILE"
echo "https://gist.github.com/fake123"
STUB
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
}

@test "defaults to secret by passing no visibility flag to gh" {
  gh_invocation
  run "$SCRIPT" "$SHARED" "[han] topaz-fit"
  [ "$status" -eq 0 ]
  [[ "$(cat "$GH_ARGS_FILE")" != *"--secret"* ]]
  [[ "$(cat "$GH_ARGS_FILE")" != *"--public"* ]]
}

@test "the default is accepted by a gh that only knows --public" {
  run "$SCRIPT" "$SHARED" "[han] topaz-fit"
  [ "$status" -eq 0 ]
  [[ "$output" != *"unknown flag"* ]]
}

@test "creates a public Gist only when --public is passed" {
  gh_invocation
  run "$SCRIPT" "$SHARED" "[han] topaz-fit" --public
  [ "$status" -eq 0 ]
  [[ "$(cat "$GH_ARGS_FILE")" == *"--public"* ]]
}

@test "an explicit --secret is accepted and never forwarded to gh" {
  gh_invocation
  run "$SCRIPT" "$SHARED" "[han] topaz-fit" --secret
  [ "$status" -eq 0 ]
  [[ "$(cat "$GH_ARGS_FILE")" != *"--secret"* ]]
  [[ "$(cat "$GH_ARGS_FILE")" != *"--public"* ]]
}

@test "rejects an unknown flag instead of creating anything" {
  run "$SCRIPT" "$SHARED" "[han] topaz-fit" --publik
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown flag '--publik'"* ]]
  [ ! -e "$GH_ARGS_FILE" ]
}
