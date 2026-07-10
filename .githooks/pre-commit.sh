#!/usr/bin/env bash
# Version bumping moved to CI (.github/workflows/package-main.yaml).
#
# This script is intentionally a no-op. It is kept (rather than deleted) so that
# any already-installed .git/hooks/pre-commit that shells to it keeps succeeding
# instead of erroring on a missing file. .git/hooks/ is not tracked, so removing
# this file cannot disarm hooks already installed on contributors' machines --
# you must delete your own .git/hooks/pre-commit to stop bumping locally.
exit 0
