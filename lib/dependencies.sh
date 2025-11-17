#!/bin/bash

# Options:
#   --category <name>   Category selector
#   --install           Automatically install missing packages via apt
#   <files...>          Dependency manifest files to process
#
# A manifest declares dependencies in the form of a triplet:
#  category:program:package
# The package field is optional and used if the package on a Debian-ish system
# is not named for the program (i.e., qemu-user-static).
dependencies_check()
{
   local category=all install_mode=0
   local -a depfiles=()
   local -a missing=()

   while [[ $# -gt 0 ]]; do
      case "$1" in
         --category)
            category=$2
            shift 2
            ;;
         --install)
            install_mode=1
            shift
            ;;
         *)
            depfiles+=("$1")
            shift
            ;;
      esac
   done

   (( ${#depfiles[@]} )) || return 0

   for depfile in "${depfiles[@]}"; do
      [[ -r "$depfile" ]] || continue
      while IFS= read -r line || [[ -n $line ]]; do
         [[ $line =~ ^[[:space:]]*(#|$) ]] && continue

         IFS=':' read -r dep_category tool pkg _ <<<"$line"
         [[ -n $dep_category ]] || continue

         [[ -n $pkg ]] || pkg=$tool
         [[ -n $tool ]] || tool=""

         if [[ $category != all && $dep_category != all && $dep_category != "$category" ]]; then
            continue
         fi

         if [[ -z $tool ]]; then
            # Package-only dependency
            dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
            continue
         fi

         if command -v "$tool" >/dev/null 2>&1; then
            continue  # installed and available
         fi

         if dpkg -s "$pkg" >/dev/null 2>&1; then
            echo "Dependency $tool ($pkg) is installed, but not found"
            exit 1  # installed but unavailable
         fi

         missing+=("$pkg") # not installed yet
      done < "$depfile"
   done

   if [[ ${#missing[@]} -gt 0 ]]; then
      local -a unique=()
      declare -A seen=()
      for pkg in "${missing[@]}"; do
         [[ -n ${seen[$pkg]:-} ]] && continue
         seen[$pkg]=1
         unique+=("$pkg")
      done

      echo "Required dependencies (${category}) not installed"
      echo
      echo "This can be resolved on Debian systems by installing:"
      echo "${unique[@]}"
      echo
      echo "Script install_deps.sh can be used for this purpose."
      echo

      if (( install_mode )); then
         apt install -y "${unique[@]}"
      else
         exit 1
      fi
   fi

    # If we're building on a native arm platform, we don't need to check for
    # binfmt_misc or require it to be loaded.

   binfmt_misc_required=1

   case $(uname -m) in
      aarch64)
         binfmt_misc_required=0
         ;;
      arm*)
         binfmt_misc_required=0
         ;;
   esac

   if [[ "${binfmt_misc_required}" == "1" ]]; then
      if ! grep -q "/proc/sys/fs/binfmt_misc" /proc/mounts; then
         echo "Module binfmt_misc not loaded in host"
         echo "Please run:"
         echo "  sudo modprobe binfmt_misc"
         exit 1
      fi
   fi
}


dependencies_install()
{
   if [ "$(id -u)" != "0" ]; then
      >&2 echo "Please run as root to install dependencies."; exit 1
   fi
   local category=all
   while [[ $# -gt 0 ]]; do
      case "$1" in
         --category)
            category=$2
            shift 2
            ;;
         *)
            break
            ;;
      esac
   done
   dependencies_check --install --category "$category" "$@"
}
