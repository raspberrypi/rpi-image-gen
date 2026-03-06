#!/bin/bash

set -eu


fstabs=()
opts=()
pmap_installed=false

pmap="${IGconf_image_outputdir}/provisionmap.json"

if [ -f "$pmap" ] ; then
   # Validate installed Provisioning Map against its schema
   pmap --schema "$IGconf_image_pmap_schema" --file "$pmap" ||
      die "IDP: Installed Provisioning Map failed validation."
   pmap_installed=true
   opts+=('-m' "$pmap")
else
   warn "IDP: No Provisioning Map installed. Raspberry Pi provisioning flow unsupported."
fi

if [ "${IGconf_image_provider:-}" = "genimage" ] && [ -f ${1}/genimage.cfg ] ; then
   fstabs+=("${1}"/fstab*)
   for f in "${fstabs[@]}" ; do
      if [ -f "$f" ] ; then
         opts+=('-f' $f)
      fi
   done

   # Generate the IDP doc
   image2json -g ${1}/genimage.cfg "${opts[@]}" > ${1}/image.json ||
      die "IDP: Doc generation failed."

   # Validate IDP doc against IDP schema
   pmap --schema "$IGconf_image_idp_schema" --file "${1}/image.json" ||
      die "IDP: Image Description Provisioning doc failed validation."

   # Validate spliced PMAP within the IDP doc against the PMAP schema
   if $pmap_installed ; then
      pmap --schema "$IGconf_image_pmap_schema" --file "${1}/image.json" ||
         die "IDP: Merged PMAP failed validation."
   fi
fi


files=()

for f in "${1}/${IGconf_image_name}"*.${IGconf_image_suffix} ; do
   files+=($f)
   [[ -f "$f" ]] || continue

   # Ensure that the output image is a multiple of the selected sector size
   truncate -s %${IGconf_device_sector_size} $f
done
