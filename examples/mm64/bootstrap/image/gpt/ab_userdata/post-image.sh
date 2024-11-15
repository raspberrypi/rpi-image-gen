#!/bin/sh

set -eu

imgf="${IGconf_image_outputdir}/${IGconf_image_name}.$IGconf_image_suffix"

case ${IGconf_image_compression} in
   zstd)
      zstd -v -f $imgf --output-dir-flat $IGconf_image_deploydir
      ;;

   none|*)
      install -v -D -m 644 $imgf $IGconf_image_deploydir
      ;;
esac


