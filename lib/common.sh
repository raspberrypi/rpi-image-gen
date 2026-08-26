#!/bin/bash


msg() {
   echo -e "$*"
}
export -f msg


warn (){
   >&2 msg "Warning: $*"
}
export -f warn


err (){
   >&2 msg "Error: $*"
}
export -f err


die (){
   [[ -n "$*" ]] && err "$*"
   exit 1
}
export -f die


run()
{
   env "$@"
   _ret=$?
   if [[ $_ret -ne 0 ]]
   then
      die "run[$*] ($_ret)"
   fi
}
export -f run


# run -i with a set of standard env variables
runsafe()
{
   # run wraps env, but env needs its own options (including -C) ahead of any
   # key=value, so a leading -C from a caller has to stay ahead of what we add
   local args=("$@") copt=()
   if [[ ${1:-} == -C ]]; then
      copt=("$1" "$2")
      args=("${@:3}")
   fi

   # Run in a clean room with var whitelist
   run -i "${copt[@]}" \
      PATH="${PATH:-}" \
      SHELL="${SHELL:-}" \
      HOME="${HOME:-}" \
      ${TERM:+TERM="$TERM"} \
      ${PYTHONPATH:+PYTHONPATH="$PYTHONPATH"} \
      ${NS_SETUP:+NS_SETUP="$NS_SETUP"} \
      ${_NS_APT_ARCHIVES:+_NS_APT_ARCHIVES="$_NS_APT_ARCHIVES"} \
      "${args[@]}"
   _ret=$?
   if [[ $_ret -ne 0 ]]
   then
      die "runsafe[$*] ($_ret)"
   fi
}
export -f runsafe


rund()
{
   if [ "$#" -gt 1 ] && [ -d  "$1" ] ; then
      local _dir="$1"
      shift 1

      local clean=0
      [[ ${1:-} == -s ]] && { clean=1; shift 1; }

      if [[ $clean -eq 1 ]]; then
         runsafe -C "$_dir" "$@"
      else
         run -C "$_dir" "$@"
      fi
   fi
}
export -f rund


# Command runner with env wrapper
runenv() {
    local file=$1; shift
    [[ -r $file ]] || die "Cannot read env file '$file'"

    # collect env options
    local -a env_opts
    local safe=0
    while (( $# )); do
       case $1 in
          -C) env_opts+=("$1" "$2"); shift 2 ;;
          -s) safe=1; shift 1 ;;
          --) shift; break ;; # explicit terminate
          *)  break ;;
       esac
    done

    # remaining words are the command to run
    local -a cmd=("$@")

    # convert to kv
    local -a env_args
    while IFS='=' read -r k v; do
       env_args+=("$k=$v")
    done < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d;s/"//g' "$file")

    if [[ $safe -eq 1 ]]; then
       runsafe "${env_opts[@]}" "${env_args[@]}" "${cmd[@]}"
    else
       run "${env_opts[@]}" "${env_args[@]}" "${cmd[@]}"
    fi
}
export -f runenv


# Retrieve a variable from a file containing key value pairs
get_var() {
   local key="$1" file="$2"
   local line value

   if line=$(grep "^${key}=" "$file" 2>/dev/null); then
      value="${line#*=}"
      value="${value#\"}"
      value="${value%\"}"
      [[ -n "$value" ]] && { echo "$value"; return 0; }
   fi
   return 1
}


# General purpose key=value file read with command callback
mapfile_kv() {
   local file cmd key val
   file=$1; shift || die "$0 missing file"
   cmd=$1;  shift || die "$0 missing callback"

   # Verify callback exists and is executable in this shell
   if ! type -t "$cmd" &>/dev/null; then
       die "$0 '$cmd' is not a function or executable command"
   fi

   [[ -r $file ]] || die "$0 cannot read $file"

   # FIXME use get_var
   while IFS= read -r line || [[ -n $line ]]; do
      key=${line%%=*}
      val=${line#*=}
      val=${val#\"}
      val=${val%\"}
      "$cmd" "$key" "$val" "$@" || { err "$0 exec $cmd" ; return 1 ;}
   done < "$file"
}


# ask <prompt> [<default>]
# default: y or n   (case-insensitive). If omitted -> ‘y’.
ask () {
   local prompt=${1:-"Continue?"}
   local default=${2:-y}
   local reply

   # Build prompt string with defaults
   if [[ $default =~ ^[Yy]$ ]]; then
      prompt="$prompt [Y/n] "
   else
      prompt="$prompt [y/N] "
   fi

   while true; do
      read -r -p "$prompt" reply
      reply=${reply,,}

      # Empty reply → use default
      [[ -z $reply ]] && reply=$default

      case $reply in
         y|yes) return 0 ;; # 0 = continue
         n|no)  return 1 ;; # 1 = abort
      esac
      echo "Please answer yes or no."
   done
}


# Translates logical asset namespaces into real paths at execution time.
# This is the central namespace path resolver for the build system. Rather than
# using hard‑coded absolute paths, logical specs are used to translate
# them at runtime. This makes hooks, overlays, layer paths etc portable, eg
# between (host) bootstrap and (container) build.
map_path() {
   local raw=$1
   [[ $raw == *:* ]] || { printf '%s\n' "$raw"; return 0; }

   local tag=${raw%%:*}
   local rest=${raw#*:}
   local base

   # Handler for variable or spec inside a variable
   if [[ $raw == VAR:* ]]; then
      local ref=${raw#VAR:}
      if [[ -z ${!ref+x} ]]; then
         return 1 # var not set -> ignore
      fi
      local val=${!ref}
      [[ -n $val ]] || return 1 # set but empty -> ignore

      if [[ $val == *:* ]]; then
         map_path "$val" # Yielded a spec so recurse to resolve
      else
         printf '%s\n' "$val"
      fi
      return 0
   fi

   case $tag in
      IGROOT)
         base=${IGTOP:?"IGTOP not set for $raw"}
         ;;
      SRCROOT)
         [[ -n ${SRCROOT:-} ]] || return 1
         base=$SRCROOT
         ;;
      IG*)
         base="${IGTOP}/${tag#IG}"
         ;;
      SRC*)
         [[ -n ${SRCROOT:-} ]] || return 1
         base="${SRCROOT}/${tag#SRC}"
         ;;
      DEVICE_ASSET)
         [[ -n ${IGconf_device_assetdir:-} ]] || return 1
         base=${IGconf_device_assetdir}
         ;;
      IMAGE_ASSET)
         [[ -n ${IGconf_image_assetdir:-} ]] || return 1
         base=${IGconf_image_assetdir}
         ;;
      DYN*)
         [[ -n ${DYNROOT:-} ]] || return 1
         base="${DYNROOT}/${tag#DYN}"
         ;;
      TARGETDIR)
         [[ -n ${IGconf_target_dir:-} ]] || return 1
         base=${IGconf_target_dir}
         ;;
      *)
         printf '%s\n' "$raw"
         return 0
         ;;
   esac

   if [[ -z $rest || $rest == "." ]]; then
      printf '%s\n' "$base"
   elif [[ $rest == /* ]]; then
      printf '%s\n' "$(realpath -m "$rest")"
   else
      printf '%s\n' "$(realpath -m "$base/$rest")"
   fi
}
export -f map_path


# Write out a layer's pre config in mmdebstrap keyed YAML at the given path.
# Optional. Loaded immediately before the layer's own YAML. Use to influence
# the order of operations when bdebstrap merges all YAML prior to mmdebstrap
# handoff.
# $1 = layer name
# $2 = layer version
# $3 = layer's static YAML path
# $4 = path to write the synthesised file to
synth_layer_pre() {
   local name=$1 version=$2 layer=$3 out=$4
   local stempath=${layer%.yaml}
   local hooks=() overlay

   # Overlays this layer applies during customize, in this order.
   # Overlays for all other phases are applied by bin/runner.
   for overlay in "${stempath}.d/rootfs-overlay" "${stempath}.d/overlay" "${stempath}.d/customize.overlay"; do
      [[ -d $overlay ]] || continue
      hooks+=( "rsync -a --chmod=go-w --exclude='.keep' --exclude='.empty' \"$overlay/\" \"\$1/\"" )
   done

   [[ ${#hooks[@]} -gt 0 ]] || return 0

   msg "synth:pre $name $version"
   {
      echo 'mmdebstrap:'
      echo '  customize-hooks:'
      local h
      for h in "${hooks[@]}"; do
         printf '    - %s\n' "$h"
      done
   } > "$out"
}
export -f synth_layer_pre


# Write out a layer's post config in mmdebstrap keyed YAML at the given path.
# Optional. Loaded immediately after the layer's own YAML. Use to influence
# the order of operations when bdebstrap merges all YAML prior to mmdebstrap
# handoff.
# $1 = layer name
# $2 = layer version
# $3 = layer's static YAML path
# $4 = path to write the synthesised file to
synth_layer_post() {
   :
}
export -f synth_layer_post


# Emits the resolved path of every layer in the plan that declares an
# mmdebstrap: mapping. A layer absent from this list contributes no config of
# its own to the bdebstrap chain, but may still contribute synthesised pre/post
# config, eg for an overlay it ships.
mmdebstrap_layer_paths() {
   python3 -c '
import sys, pathlib, yaml
for raw in pathlib.Path(sys.argv[1]).read_text().splitlines():
    if not raw or raw.startswith("#"):
        continue
    parts = raw.split(":", 3)
    if len(parts) != 4 or not parts[0] or not parts[3]:
        continue
    layer, version, static, resolved = parts
    try:
        data = yaml.safe_load(open(resolved, "rb"))
    except Exception as e:
        print(f"{resolved}: {e}", file=sys.stderr)
        sys.exit(2)
    if isinstance(data, dict) and data.get("mmdebstrap"):
        print(resolved)
' "$1"
}
export -f mmdebstrap_layer_paths


# foreach_layer_in_plan: calls callback once per layer in plan order:
# Expects: callback layer version stempath [extra args]
# stempath is the layer's static filename path with .yaml stripped so
# directly usable to derive its companion dir path <stempath>.d.
# Uses the caller's own $PLAN when in scope (bin/runner's own calls), else
# derives it.
foreach_layer_in_plan() {
   local callback=${1:?"foreach_layer_in_plan: callback required"}; shift
   local plan=${PLAN:-${IGconf_sys_bootstrapdir:?"foreach_layer_in_plan: IGconf_sys_bootstrapdir not set"}/layer.plan}
   local layer version static resolved stempath

   [[ -f $plan ]] || return 0
   while IFS=: read -r layer version static resolved; do
      [[ -n $layer && $layer != \#* ]] || continue
      stempath="${static%.yaml}"
      "$callback" "$layer" "$version" "$stempath" "$@"
   done < "$plan"
}
export -f foreach_layer_in_plan


# General purpose key=value normaliser that escapes characters that would
# break shell expansion.
safe_kv() {
  python3 - "$1" <<'PY'
import sys
import re
with open(sys.argv[1], encoding='utf-8') as src:
   for raw in src:
      line = raw.rstrip('\n')
      if not line or line.lstrip().startswith('#') or '=' not in line:
         print(line)
         continue
      key, value = line.split('=', 1)
      value = value.replace('\\', '\\\\').replace('"', '\\"').replace('`', '\\`')
      # Permits ${var} or $(cmd) expansion, escapes $6$salt$hash
      value = re.sub(r'\$(?![({])', r'\\$', value)
      print(f'{key}="{value}"')
PY
}


checkpath_world_exec() {
   [[ -n "${1:-}" ]] || die "missing path"
   local path mode
   path=$(realpath -e "$1") || die "path does not exist: $1"

   # Walk up path checking parents
   while [[ -n "$path" ]]; do
      # %a yields octal, eg 755
      # 8# prefix indicates an octal number
      # Logical test checks if world execute is set
      # ACL bits not supported (getfacl)
      mode=$(stat -c "%a" "$path" 2>/dev/null) || return 1

      if [[ $((8#$mode & 1)) -eq 0 ]]; then
         warn "$path $mode"
         return 1
      fi

      # Move up one level
      [[ "$path" == "/" ]] && break
      path=$(dirname "$path")
   done
   return 0
}


# apt (_apt user) requires world execute permissions on all leading paths. This
# wraps a recursive dir check with strict mkdir and policy decisions.
xmkdir() {
   local dir="$1"
   [[ -n "$dir" ]] || die "xmkdir: missing directory"

   if [[ -e "$dir" && ! -d "$dir" ]]; then
      die "xmkdir: not a directory: $dir"
   elif [[ ! -d "$dir" ]]; then
      install -d -m 0755 "$dir" || die "xmkdir: failed to create directory: $dir"
   else
      :
   fi
   checkpath_world_exec "$dir" || warn "xmkdir: $dir or ancestor not o+x (apt may fail)"
}
