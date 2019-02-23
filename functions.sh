#!/usr/bin/env bash

cpu_core_count(){
  if command -v nproc &>/dev/null; then
    nproc
  elif command -v sysctl &>/dev/null; then
    sysctl -n hw.ncpu
  elif [[ -f /proc/cpuinfo ]]; then
    grep -c 'processor' /proc/cpuinfo
  else
    echo 1
  fi
  return $?
}

function_defined(){
  if [[ ${1:-UNDEFINED} == 'UNDEFINED' ]]; then
    echo 'no function name specified' >&2
    return 2
  fi

  type "${1}" | head -n1 | grep -q 'is a function'
  retval=$?

  if [[ ${retval} == 0 ]]; then
    echo "true"
    return
  fi

  echo 'false'
  return 1
}

is_gnu(){
  # false if utility doesn't exist
  if ! which "${1}" > /dev/null 2>&1; then
    echo "false"
    return 1
  fi

  # true if utility exists and says it's GNU
  if "${1}" --version 2>&1 | grep -qi 'gnu'; then
    echo "true"
    return 0
  fi

  # false otherwise
  echo "false"
  return 1
}

serve() {
  local port="${1:-3000}"

  if type -P webfsd &> /dev/null; then
    webfsd -d -s -l - -F -p "${port}" -r "${PWD}" -f index.html
  else
    python -m SimpleHTTPServer "${port}"
  fi
}

shrug() {
  echo "¯\_(ツ)_/¯"
  return 0
}

table() {
  case "${1}" in
    flip)
      echo "（╯°□°）╯︵ ┻━┻ "
    ;;
    set)
      echo "┬─┬﻿ ノ( ゜-゜ノ)"
    ;;
    man)
      echo "(╯°Д°）╯︵ /(.□ . \)"
    ;;
    bear)
      echo "ʕノ•ᴥ•ʔノ ︵ ┻━┻"
    ;;
    jedi)
      echo "(._.) ~ ︵ ┻━┻"
    ;;
    pudgy)
      echo "(ノ ゜Д゜)ノ ︵ ┻━┻"
    ;;
    battle)
      echo "(╯°□°)╯︵ ┻━┻ ︵ ╯(°□° ╯)"
    ;;
    rage)
      echo "‎(ﾉಥ益ಥ）ﾉ﻿ ┻━┻"
    ;;
    herc)
      echo "(/ .□.)\ ︵╰(゜Д゜)╯︵ /(.□. \)"
    ;;
    *)
      echo "Unknown table" >&2
      echo "Try:" >&2
      echo -e "  flip" >&2
      echo -e "  set" >&2
      echo -e "  man" >&2
      echo -e "  bear" >&2
      echo -e "  jedi" >&2
      echo -e "  pudgy" >&2
      echo -e "  battle" >&2
      echo -e "  rage" >&2
      echo -e "  herc" >&2
    ;;
  esac
  return 0
}

notify(){
  echo -e "${1}"
}

error(){
  notify "${1}" >&2
}

abort(){
  notify "${__self}: ${1}" >&2
  exit 1
}

trim_leading(){
  local str="${*}"

  # remove leading whitespace characters
  str="${str#"${str%%[![:space:]]*}"}"

  echo -n "${str}"
  return "${?}"
}

trim_trailing(){
  local str="${*}"

  # remove trailing whitespace characters
  str="${str%"${str##*[![:space:]]}"}"
  echo -n "${str}"
  return "${?}"
}

uri_path() {
  if ( ! command -v realpath &>/dev/null ); then
    echo "ERROR: ${FUNCNAME} requires the 'realpath' command exist in the PATH" >&2
    return 1
  fi

  local file_path
  file_path="${1:-UNSET}"

  if [[ ${file_path} == 'UNSET' ]]; then
    echo "ERROR: ${FUNCNAME} requires a path" >&2
    return 1
  fi

  echo "file://$(realpath --no-symlinks --canonicalize-missing "${file_path}")"
  return 0
}

# find dead symlinks in the current directory or $1
deadlinks(){
  local __path="${1:-./}"
  find -L "${__path}" -type l -print
}

# How old is a PID? This is a good approximation
pid_dob() {
  local __file="/proc/${1}"

  if [ ! -d "${__file}" ]; then
    echo "No such PID ${1} found" >&2
    return 1
  fi

  local __mtime=$(stat "${__file}" | grep Modify | cut -f2- -d':' | sed -e 's/^ *//g' -e 's/ *$//g')
  local __pretty=$(date -d "${__mtime}" '+%a %b %d, %r')

  echo "PID ${1} last modified ${__pretty}"
  return $?
}

uuidgen() {
  if ( ! command -v uuidgen &>/dev/null ); then
    python -c 'import uuid; print str(uuid.uuid4())'
    return $?
  fi
  /usr/bin/env uuidgen
}

to_lower() {
  tr '[:upper:]' '[:lower:]'
}

to_upper() {
  tr '[:lower:]' '[:upper:]'
}

pretty_json() (
  if ( ! command -v jq &>/dev/null ); then
    echo "ERROR: ${FUNCNAME} requires the 'jq' command exist in the PATH" >&2
    return 1
  fi

  local input

  # Use stdin if it's provided, otherwise assume $1 is a file
  if [ $# -ge 1 ] && [ -f "${1}" ]; then
    input="${1}"
  else
    input="-"
  fi

  jq . "${input}"
  return $?
)

whitespace() {
  local character="${1}"
  local quantity="${2:-$LINES}"
  local iterator=0

  while [[ ${iterator} -lt ${quantity} ]]; do
    printf "%s\n" "${character}"
    ((iterator+=1))
  done
  return $?
}
alias ws=whitespace

write_image(){
  local size
  size="$(/usr/bin/stat -f%z "${1}")"

  sudo echo -n
  /bin/dd if="${1}" |
    pv --wait --size "${size}" |
    sudo dd of="${2}"
}

function urldecode(){
  local url="${1}"
  python -c "import sys, urllib; print urllib.unquote_plus('${url}')"
  return $?
}

function urlencode(){
  local url="${1}"
  python -c "import sys, urllib; print urllib.quote_plus('${url}')"
  return $?
}

statuscode() {
  [[ ${1:-UNSET} == "UNSET" ]] && return 1
  local action="${2:-GET}"

  curl \
    --request "${action}" \
    --silent \
    --include \
    --write-out "%{url_effective} %{http_code}\\n" \
    --output /dev/null \
    "${1}"
  return $?
}

contenttype() {
  [[ ${1:-UNSET} == "UNSET" ]] && return 1;
  local action="${2:-GET}";

  curl \
    --request "${action}" \
    --silent \
    --include \
    --location \
    --write-out "%{url_effective} %{content_type}\\n" \
    --output /dev/null \
    "${1}"
  return $?
}

headers() {
  [[ ${1:-UNSET} == "UNSET" ]] && return 1

  curl \
    --request GET \
    --silent \
    --include \
    --location \
    --head \
    "${1}"
  return $?
}

curl-sha256(){
  [[ ${1:-UNSET} == "UNSET" ]] && return 1

  curl \
    --progress-bar \
    --location \
    "${1}" |
  sha256sum |
  awk '{print $1}'
  return $?
}

curl-md5sum(){
  [[ ${1:-UNSET} == "UNSET" ]] && return 1

  curl \
    --progress-bar \
    --location \
    "${1}" |
  md5sum |
  awk '{print $1}'
  return $?
}

epoch(){
  if [[ ${1:-UNSET} == "UNSET" ]]; then
    date '+%s'
  else
    /usr/bin/ruby -rdate -e "puts Date.parse('${1}').strftime('%s')"
  fi
}

mx() {
  [[ ${1:-UNSET} == "UNSET" ]] && return 1
  dig +short mx "${1}" | sort | tr "[:upper:]" "[:lower:]"
}

nameservers() {
  [[ ${1:-UNSET} == "UNSET" ]] && return 1
  dig +short ns "${1}" | sort | tr "[:upper:]" "[:lower:]"
}

realpath() {
  if [[ -z "${1}" ]]; then
    return 1
  fi

  if ! type -P realpath; then
    python -c "import os; print(os.path.realpath('${1}'))"
    return $?
  fi

  command realpath "${1}"
}

paths() {
  xargs -n1 -d: <<< "${PATH}" | awk '!x[$0]++'
}

where(){
  if [[ -z "${1}" ]]; then
    echo "where() requires an argument" >&2
    return 1
  fi

  local name
  name="${1}"

  local executable_path

  while read -r path; do    
    executable_path="${path}/${name}"

    if [[ -x "${executable_path}" ]]; then
      echo "${executable_path}"
    fi
  done < <(paths)
}
