#!/bin/zsh
set -euo pipefail

target_bundle_id="com.notomo.Notomo"
target_scheme="notomo"
target_process_name="Notomo"
handoff_notification="${target_bundle_id}.popclipHandoff"
handoff_id="$(/usr/bin/uuidgen)"
handoff_dir="${HOME}/Library/Caches/${target_bundle_id}/popclip-handoff"
handoff_file="${handoff_dir}/${handoff_id}.txt"

is_target_app_running() {
  local pid command
  while read -r pid; do
    [[ -n "${pid}" ]] || continue
    command="$(/bin/ps -p "${pid}" -o comm= 2>/dev/null || true)"
    case "${command}" in
      *"/Contents/MacOS/${target_process_name}")
        return 0
        ;;
    esac
  done < <(/usr/bin/pgrep -x "${target_process_name}" 2>/dev/null || true)
  return 1
}

if [[ -z "${POPCLIP_TEXT:-}" ]]; then
  exit 1
fi

/bin/mkdir -p "${handoff_dir}"
/bin/chmod 700 "${handoff_dir}"
/usr/bin/printf '%s' "${POPCLIP_TEXT}" > "${handoff_file}"
/bin/chmod 600 "${handoff_file}"

target_url="${target_scheme}://skills?handoff=${handoff_id}"
if is_target_app_running; then
  /usr/bin/osascript <<APPLESCRIPT
use framework "Foundation"
current application's NSDistributedNotificationCenter's defaultCenter()'s postNotificationName:"${handoff_notification}" object:"${handoff_id}" userInfo:(missing value) deliverImmediately:true
APPLESCRIPT
else
  /usr/bin/open -g -b "${target_bundle_id}" "${target_url}"
fi
