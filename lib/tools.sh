#!/bin/bash

# Dynamic package build selection. Typically, X-Env Triggers set defined
# variables which map to the package registry below. These compoments are
# built and installed as prerequisites in a reusable mini-sysroot.
# Can scale as needed, eg move away from bash array to file. Main thing
# is to retain functionality: vars -> registry -> selection -> action
readonly -a IG_TOOLS_REGISTRY=(
   "IG_ENABLE_HOST_GENIMAGE|y|genimage"
)

collect_build_deps() {
   local envfile="${1:?missing env file}"
   local packages=(bdebstrap) # mandatory
   local var value pkg

   for entry in "${IG_TOOLS_REGISTRY[@]}"; do
      IFS='|' read -r var value pkg <<< "$entry"
      if value_read=$(get_var "$var" "$envfile") && [[ "$value_read" == "$value" ]]; then
         packages+=("$pkg")
      fi
   done
   echo "${packages[*]}"
}


bootstrap_build_tools() {
   : "${ctx[FINALENV]?missing ctx[FINALENV]}"
   : "${IGconf_sys_workroot?missing IGconf_sys_workroot}"
   : "${DEB_BUILD_GNU_TYPE?missing DEB_BUILD_GNU_TYPE}"

   local tools=( $(collect_build_deps "${ctx[FINALENV]}") )
   local destdir="${IGconf_sys_workroot}/${DEB_BUILD_GNU_TYPE}"
   local prefix=/usr

   runenv "${ctx[FINALENV]}" \
      make -s -j"$(nproc)" -C "${IGTOP}/package" "${tools[@]}" \
      PKG_DESTDIR="$destdir" PKG_PREFIX="$prefix"

   # prepend host tool paths
   PATH="${destdir}${prefix}/local/bin:${destdir}${prefix}/bin:${PATH}"
   export PATH

   local pyver
   pyver=$(python3 -c 'import sysconfig; print("python"+sysconfig.get_python_version())')
   PYTHONPATH="${destdir}${prefix}/local/lib/${pyver}/dist-packages:${destdir}${prefix}/lib/${pyver}/dist-packages:${PYTHONPATH:-}"
   export PYTHONPATH
}
