#!/bin/bash

set -eo pipefail

IGTOP=$(readlink -f $(dirname "$0"))


# TODO need top level selectors for:
#  external dir
#  external namespace
# These will be used to override/augment paths for sub-directories to
# facilitate third-party customisation, e.g.
# /<dir>/
#        meta/<namespace>/ [augment]
#        profile/          [override]
#        config/           [override]
#        board/            [override]
#        image/            [override]

IGTOP_PROFILE=${IGTOP}/profile
IGTOP_CONFIG=${IGTOP}/config
IGTOP_BOARD=${IGTOP}/board
IGTOP_IMAGE=${IGTOP}/image


# Internalise directory structure variables
META=$IGTOP/meta
META_HOOKS=$IGTOP/meta-hooks
RPI_TEMPLATES=$IGTOP/templates/rpi


# TODO get from top level arg, eg -p generic64-min-ab
INCONFIG=generic64-apt-ab
test -s ${IGTOP_CONFIG}/${INCONFIG}.cfg || (>&2 echo ${IGTOP_CONFIG}/${INCONFIG}.cfg is invalid; exit 1)


# Read config
read_config_section image ${IGTOP_CONFIG}/${INCONFIG}.cfg
read_config_section system ${IGTOP_CONFIG}/${INCONFIG}.cfg
read_config_section target ${IGTOP_CONFIG}/${INCONFIG}.cfg

# Defaults
: ${IGconf_target_board:=pi5}
: ${IGconf_image_name:="${IGconf_target_board}-${INCONFIG}"}
: ${IGconf_image_suffix:=img}

[[ -z ${IGconf_image_layout+x} ]] && (>&2 echo config has no image layout; exit 1)
[[ -z ${IGconf_system_profile+x} ]] && (>&2 echo config has no profile; exit 1)

test -d ${IGTOP_IMAGE}/$IGconf_image_layout || (>&2 echo image layout "$IGconf_image_layout" is invalid; exit 1)
test -f ${IGTOP_PROFILE}/$IGconf_system_profile || (>&2 echo profile "$IGconf_system_profile" is invalid; exit 1)
test -d ${IGTOP_BOARD}/$IGconf_target_board || (>&2 echo board "$IGconf_target_board" is invalid; exit 1)


# Read and validate options. Options can override config.
# TODO read options file via top level.
# These could be aggregated with the config file.
# TODO decide to retain/change any existing pi-gen variable names.
read_options << EOF
APT_PROXY=$APT_PROXY
LOCALE_DEFAULT="$LOCALE_DEFAULT"
TIMEZONE_DEFAULT="$TIMEZONE_DEFAULT"
FIRST_USER_NAME="$FIRST_USER_NAME"
FIRST_USER_PASS="$FIRST_USER_PASS"
KEYBOARD_LAYOUT="$KEYBOARD_LAYOUT"
KEYBOARD_KEYMAP="$KEYBOARD_KEYMAP"
TARGET_HOSTNAME="$TARGET_HOSTNAME"
IMG_NAME="$IMG_NAME"
IMG_SUFFIX="$IMG_SUFFIX"
DEPLOY_DIR="$DEPLOY_DIR"
EOF


# post-options:
IGconf_image_name="${IGopt_IMG_NAME:-$IGconf_image_name}"
IGconf_image_suffix="${IGopt_IMG_SUFFIX:-$IGconf_image_suffix}"

WORKROOT="${IGopt_WORK_DIR:-${IGTOP}/work/${IGconf_image_name}}"

: ${IGconf_image_outputdir:=${WORKROOT}/artefacts}
IGconf_image_deploydir="${IGopt_DEPLOY_DIR:-${IGconf_image_outputdir}/deploy}"


# Assemble environment for rootfs creation
ARGS_ENV=()
ARGS_ENV+=('--env' META_HOOKS=$META_HOOKS)
ARGS_ENV+=('--env' RPI_TEMPLATES=$RPI_TEMPLATES)

# Include these options
ENV_ROOTFS_VARS=(
   IGopt_APT_PROXY
   IGopt_LOCALE_DEFAULT
   IGopt_TIMEZONE_DEFAULT
   IGopt_FIRST_USER_NAME
   IGopt_FIRST_USER_PASS
   IGopt_KEYBOARD_LAYOUT
   IGopt_KEYBOARD_KEYMAP
   IGopt_TARGET_HOSTNAME
)
for option in "${ENV_ROOTFS_VARS[@]}" ; do
   case $option in
      IGopt_TIMEZONE_DEFAULT)
         ARGS_ENV+=('--env' IGopt_TIMEZONE_AREA="${IGopt_TIMEZONE_DEFAULT%%/*}")
         ARGS_ENV+=('--env' IGopt_TIMEZONE_CITY="${IGopt_TIMEZONE_DEFAULT##*/}")
         ;;
      IGopt_APT_PROXY)
         ARGS_ENV+=('--env' IGopt_APT_PROXY_HTTP="${IGopt_APT_PROXY}")
         ;;
      *)
         ARGS_ENV+=('--env' ${option}="${!option}")
         ;;
   esac
done


# Assemble meta layers from profile
ARGS_LAYERS=()
while read -r line; do
   [[ "$line" =~ ^#.*$ ]] && continue
   [[ "$line" =~ ^$ ]] && continue
   # TODO augment search with external meta dir and namespace
   test -f $META/$line.yaml || (>&2 echo invalid meta specifier: "$line"; exit 1)
   ARGS_LAYERS+=('--config' $META/$line.yaml)
done < ${IGTOP_PROFILE}/$IGconf_system_profile


# Generate rootfs
podman unshare bdebstrap \
   "${ARGS_LAYERS[@]}" \
   "${ARGS_ENV[@]}" \
   --name $IMG_NAME \
   --hostname $IGopt_TARGET_HOSTNAME \
   --output ${IGconf_image_outputdir} \
   --target ${WORKROOT}/rootfs


# post-build: assemble environment for subsequent operations
POST_BUILD_VARS=(
   IGconf_system_profile
   IGconf_target_board
   IGconf_image_layout
   IGconf_image_name
   IGconf_image_suffix
   IGconf_image_outputdir
   IGconf_image_deploydir
   IGconf_image_compression
)
ENV_POST_BUILD=()
for option in "${POST_BUILD_VARS[@]}" ; do
   ENV_POST_BUILD+=(${option}="${!option}")
done


# hook execution
runh()
{
   local hookdir=$(dirname "$1")
   local hook=$(basename "$1")
   shift 1
   echo "IG:" "$hookdir"["$hook"] "$@"
   env -C $hookdir "${ENV_POST_BUILD[@]}" ./"$hook" "$@"
   ret=$?
   if [[ $ret -ne 0 ]]
   then
      >&2 echo "Hook Error: ["$hookdir"/"$hook"] ($ret)"
      exit $ret
   fi
}


# cmd execution
run()
{
   echo "IG:" "$@"
   env "$@"
   ret=$?
   if [[ $ret -ne 0 ]]
   then
      >&2 echo "Error: [$@] ($ret)"
      exit $ret
   fi
}


# post-build: apply rootfs overlays - image layout then board
if [ -d ${IGTOP_IMAGE}/$IGconf_image_layout/rootfs-overlay ] ; then
   run rsync -a ${IGTOP_IMAGE}/$IGconf_image_layout/rootfs-overlay/ ${WORKROOT}/rootfs
fi
if [ -d ${IGTOP_BOARD}/$IGconf_target_board/rootfs-overlay ] ; then
   run rsync -a ${IGTOP_BOARD}/$IGconf_target_board/rootfs-overlay/ ${WORKROOT}/rootfs
fi


# post-build: hooks - image layout then board
if [ -x ${IGTOP_IMAGE}/$IGconf_image_layout/post-build.sh ] ; then
   runh ${IGTOP_IMAGE}/$IGconf_image_layout/post-build.sh ${WORKROOT}/rootfs
fi
if [ -x ${IGTOP_BOARD}/$IGconf_target_board/post-build.sh ] ; then
   runh ${IGTOP_BOARD}/$IGconf_target_board/post-build.sh ${WORKROOT}/rootfs
fi


# pre-image: hooks - board has priority over image layout
if [ -x ${IGTOP_BOARD}/$IGconf_target_board/pre-image.sh ] ; then
   runh ${IGTOP_BOARD}/$IGconf_target_board/pre-image.sh ${WORKROOT}/rootfs ${WORKROOT}
elif [ -x ${IGTOP_IMAGE}/$IGconf_image_layout/pre-image.sh ] ; then
   runh ${IGTOP_IMAGE}/$IGconf_image_layout/pre-image.sh ${WORKROOT}/rootfs ${WORKROOT}
else
   >&2 echo "no pre-image hook"
fi


GTMP=$(mktemp -d)
trap 'rm -rf $GTMP' EXIT
mkdir -p "$IGconf_image_deploydir"


# Generate image(s)
for f in "${WORKROOT}"/genimage*.cfg; do
   podman unshare genimage \
      --rootpath ${WORKROOT}/rootfs \
      --tmppath $GTMP \
      --inputpath ${WORKROOT}   \
      --outputpath ${IGconf_image_outputdir} \
      --loglevel=10 \
      --config $f
done


# post-image: hooks - board has priority over image layout
if [ -x ${IGTOP_BOARD}/$IGconf_target_board/post-image.sh ] ; then
   runh ${IGTOP_BOARD}/$IGconf_target_board/post-image.sh $IGconf_image_deploydir
elif [ -x ${IGTOP_IMAGE}/$IGconf_image_layout/post-image.sh ] ; then
   runh ${IGTOP_IMAGE}/$IGconf_image_layout/post-image.sh $IGconf_image_deploydir
else
   :
fi
