#!/usr/bin/env bash

fetch_deps() {
  local PROJ_DIR; PROJ_DIR="$(dirname -- "${BASH_SOURCE[0]}")/.."

  local DEPS_FILE=deps.txt
  local DEST_DIR=requirements

  cd -- "${PROJ_DIR}" || return

  ! cat -- "${DEPS_FILE}" &>/dev/null && return

  (set -x; rm -rf "${DEST_DIR:?}/"{bookshelf,roles})

  local temp; temp="$(set -x; mktemp -d)"

  local line name dl_url
  while IFS= read -r line; do
    name="${line%%=*}"
    dl_url="${line#*=}"

    (set -o pipefail; set -x; curl -fsSL -- "${dl_url}" | tar -xzf - -C "${temp}") || return
    (set -x; mkdir -p -- "${DEST_DIR}/bookshelf/${name}") || return

    if cat -- "${temp:?}"/*/requirements.yaml &>/dev/null; then
      (set -x; mv -- "${temp:?}"/*/requirements.yaml "${DEST_DIR}/bookshelf/${name}") || return
    fi
    (set -x; mv -- "${temp:?}"/*/{sample,playbook.yaml} "${DEST_DIR}/bookshelf/${name}") || return
    (set -x; cp -rf -- "${temp:?}"/*/roles "${DEST_DIR}/") || return

    (set -x; rm -rf -- "${temp:?}"/*) || return
  done < <(
    grep -v '^\s*\(#.\+\)\?\s*$' "${DEPS_FILE}" \
    | sed -e 's/^\s*//' -e 's/\s*$//' -e 's/\s*=\s*/=/'
  )

  (set -x; rm -rf -- "${temp:?}")
}

(return 2>/dev/null) || fetch_deps
