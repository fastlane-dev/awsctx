#!/bin/bash

AWSCTX="${XDG_CACHE_HOME:-$HOME/.aws}/awsctx"
AWS_ACCOUNT_CODE_DEV="699158113629"

_awsctx_usage() {
  cat <<"EOF"
USAGE:
  awsctx                       : list the profiles
  awsctx <NAME>                : switch to profile <NAME>

  awsctx -h,--help             : show this message
EOF
}

_awsctx_export_profile() {
  export AWS_PROFILE="${1}"
}

_awsctx_persist_profile() {
  echo "${1}" > "${AWSCTX}"
}

_awsctx_restore_profile() {
  local cached
  if [[ -f "${AWSCTX}" ]]; then
    cached="$(cat ${AWSCTX})"
    if [[ -n "${cached}" ]]; then
      _awsctx_export_profile "${cached}"
    fi
  fi
}

_awsctx_set_profile() {
  if [[ -n "$1" ]]; then
    _awsctx_export_profile "${1}"
    _awsctx_persist_profile "${1}"
    echo Switched to profile \""${1}"\"
  fi
}

_awsctx_switched_banner() {
  account_code=`aws sts get-caller-identity --query "Account" --output text`
  if [[ "${account_code}" == "${AWS_ACCOUNT_CODE_DEV}" ]]; then
    echo ""
  else
    echo " __  __  __  __  "
    echo "|__)|__)/  \|  \ "
    echo "|   | \ \__/|__/ "
    echo ""
  fi
}

_awsctx_list_profiles() {
  local cmd
  cmd="$(_awsctx_get_fzf_command)"
  eval "${cmd}"
}

_awsctx_get_fzf_command() {
  local creds_file
  creds_file="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
  echo "sed -ne 's/\[\(.*\)\]/\1/p' ${creds_file} | sed -e 's/^\(${AWS_PROFILE}\)$/$(tput setab 0)$(tput setaf 3)\1$(tput sgr0)/g'"
}

_awsctx_choose_profile_interactive() {
  local choice fzf_command
  fzf_command="$(_awsctx_get_fzf_command)"
  choice=`FZF_DEFAULT_COMMAND="${fzf_command}" fzf --ansi`
  if [[ -n "${choice}" ]]; then
    _awsctx_set_profile "${choice}"
    _awsctx_switched_banner
  fi
}


awsctx() {
  if [[ "$#" -gt 1 ]]; then
    echo "error: too many arguments" >&2
    _awsctx_usage
  elif [[ "$#" -eq 1 ]]; then
    if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
      _awsctx_usage
    elif [[ "${1}" =~ ^-(.*) ]]; then
      echo "error: unrecognized flag \"${1}\"" >&2
      _awsctx_usage
    else
     _awsctx_set_profile "${1}"
    fi
  elif [[ "$#" -eq 0 ]]; then
    if [[ -t 1 &&  -z "${AWSCTX_IGNORE_FZF:-}" && "$(type fzf &>/dev/null; echo $?)" -eq 0 ]]; then
      _awsctx_choose_profile_interactive
    else
      _awsctx_list_profiles
    fi
  else
    _awsctx_usage
  fi
}

_awsctx_restore_profile
