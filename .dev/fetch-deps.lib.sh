#!/usr/bin/env bash

fetch_deps() {
  local SELF_DIR; SELF_DIR="$(dirname -- "${BASH_SOURCE[0]}")"
  local PROJ_DIR; PROJ_DIR="${SELF_DIR}/.."
  local REQS_DIR=requirements
  local DEPS_FILE=deps.ini

  cp_book_files() {
    local src_dir="${1}" book_name="${2}"

    if cat -- "${src_dir}/playbook.yaml" &>/dev/null; then
      (set -x; cp -f -- "${src_dir}/playbook.yaml" "${REQS_DIR}/${book_name}.yaml") || return
    fi
    if cat -- "${src_dir}/requirements.yaml" &>/dev/null; then
      (set -x; cp -f -- "${src_dir}/requirements.yaml" "${REQS_DIR}/${book_name}.req.yaml")
    fi

    (set -x; cp -rf -- "${src_dir:?}/roles" "${REQS_DIR}/") || return
  }

  main() {
    cd -- "${PROJ_DIR}" || return
    ! cat -- "${DEPS_FILE}" &>/dev/null && return

    (set -x; rm -rf "${REQS_DIR:?}"/{roles,*.yaml} && mkdir -p -- "${REQS_DIR}")

    local line name dl_url temp
    while IFS= read -r line; do
      name="${line%%=*}"
      dl_url="${line#*=}"

      temp="$(set -x; mktemp -d)" || return
      ( set -o pipefail; set -x
        curl -fsSL -- "${dl_url}" \
        | tar --strip-components 1 -xzf - -C "${temp}"
      ) || return

      cp_book_files "${temp}" "${name}"

      (set -x; rm -rf -- "${temp:?}") || return
    done < <(
      grep -v '^\s*\([#;].*\)\?\s*$' "${DEPS_FILE}" \
      | sed -e 's/^\s*//' -e 's/\s*$//' -e 's/\s*=\s*/=/'
    )
  }

  main "${@}"
}

(return 2>/dev/null) || fetch_deps "${@}"
