# shell profile fragment

HAS_CCACHE=n

# Enable ccache if available
if { [ -d /usr/lib/ccache ] || command -v ccache >/dev/null 2>&1; } && \
   [ -d /var/cache/ccache ] && \
   [ -d /home/build ] ; then

  case ":$PATH:" in *":/usr/lib/ccache:"*) ;; *) PATH="/usr/lib/ccache:$PATH";; esac
  export PATH

  # Set defaults
  export CCACHE_DIR="${CCACHE_DIR:-/var/cache/ccache}"
  export CCACHE_COMPRESS="${CCACHE_COMPRESS:-1}"
  export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-10G}"
  export CCACHE_BASEDIR="${CCACHE_BASEDIR:-/home/build}"

  HAS_CCACHE=y
fi

# Load and export env
if [ -r /toolchain.env ]; then
   set -a
  . /toolchain.env
  set +a
fi

# Prefix compilers if ccache enabled
if [ "$HAS_CCACHE" = y ]; then
  for v in CC CXX HOSTCC HOSTCXX ; do
    if [[ -v $v ]]; then
      eval val=\"\${$v}\"
      case "$val" in ccache\ *) ;; *) eval "export $v=\"ccache \$val\"" ;; esac
    fi
  done
fi
