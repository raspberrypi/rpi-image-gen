#!/bin/bash

bootstrap_build_tools() {
   : "${ctx[FINALENV]?missing ctx[FINALENV]}"
   : "${IGconf_sys_workroot?missing IGconf_sys_workroot}"
   : "${DEB_BUILD_GNU_TYPE?missing DEB_BUILD_GNU_TYPE}"

   local tools=(bdebstrap)
   if value=$(get_var IGconf_image_provider "${ctx[FINALENV]}") \
      && [[ $value == genimage ]]; then
      tools+=(genimage)
   fi

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
