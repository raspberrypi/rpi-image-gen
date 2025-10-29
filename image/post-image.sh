#!/bin/bash

set -eu


if [ -f ${1}/genimage.cfg ] ; then
   fstabs=()
   opts=()
   fstabs+=("${1}"/fstab*)
   for f in "${fstabs[@]}" ; do
      if [ -f "$f" ] ; then
         opts+=('-f' $f)
      fi
   done

   pmap="${IGconf_image_outputdir}/provisionmap.json"
   if [ -f "$pmap" ] ; then
      # Validate pmap against the schema
      pmap --schema "$IGconf_image_pmap_schema" --file "$pmap" ||
         die "Installed Provisioning Map failed to validate."
      opts+=('-m' "$pmap")
   fi

   # Generate description for IDP
   image2json -g ${1}/genimage.cfg "${opts[@]}" > ${1}/image.json
fi


files=()

for f in "${1}/${IGconf_image_name}"*.${IGconf_image_suffix} ; do
   files+=($f)
   [[ -f "$f" ]] || continue

   # Ensure that the output image is a multiple of the selected sector size
   truncate -s %${IGconf_device_sector_size} $f
done
