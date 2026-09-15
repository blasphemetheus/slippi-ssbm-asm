#!/usr/bin/env bash
set -euo pipefail
exec elixir "$(dirname "$0")/build-float-inputs.exs"
