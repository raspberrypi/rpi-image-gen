#!/bin/bash

bootstrap_build_tools() {
   : "${ctx[FINALENV]?missing ctx[FINALENV]}"
   : "${ctx[EXEC_PATH]?missing ctx[EXEC_PATH]}"
   : "${ctx[PYTHON_PATH]?missing ctx[PYTHON_PATH]}"
   : "${IGconf_sys_workroot?missing IGconf_sys_workroot}
   : "${DEB_BUILD_GNU_TYPE?missing DEB_BUILD_GNU_TYPE}

   # Mission critical
   local tools=(bdebstrap)

   if value=$(get_var IGconf_image_provider "${ctx[FINALENV]}") \
      && [[ $value == genimage ]]; then
         tools+=(genimage)
   fi

   # Build and install tools to this location
   local destdir=${IGconf_sys_workroot}/${DEB_BUILD_GNU_TYPE}
   local prefix=/usr

   runenv "${ctx[FINALENV]}" \
      make -s -j$(nproc) -C ${IGTOP}/package "${tools[@]}" \
      PKG_DESTDIR=$destdir PKG_PREFIX=$prefix

   # Fixup paths to ensure installed tools run transparently. There are many
   # caveats with this approach, and it risks env leakage. Leveraging a
   # containerised build vehicle approach is preferred.
   local paths=(
      "${destdir}${prefix}/local/bin"\
      "${destdir}${prefix}/bin"\
      "${ctx[EXEC_PATH]}"
      )
   ctx[EXEC_PATH]="$(IFS=:; echo "${paths[*]}")"
   PATH="${ctx[EXEC_PATH]}"
   export PATH

   local pyver="$(python3 -c 'import sysconfig; print("python"+sysconfig.get_python_version())')"
   paths=(\
      "${destdir}${prefix}/local/lib/${pyver}/dist-packages"\
      "${destdir}${prefix}/lib/${pyver}/dist-packages"\
      "${ctx[PYTHON_PATH]}"
   )
   ctx[PYTHON_PATH]="$(IFS=:; echo "${paths[*]}")"
   PYTHONPATH="${ctx[PYTHON_PATH]}"
   export PYTHONPATH
}
