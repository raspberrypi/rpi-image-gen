#!/bin/bash

set -eu

RPI_CSS='
/* Raspberry Pi overrides */
h1 {
    color: #cd2355;
    border-bottom: 2px solid #cd2355;
    padding-bottom: 0.3em;
}
.badge-warning.required-property {
    background-color: #ffffff !important;
    color: #cd2355 !important;
    border: 1px solid #cd2355;
}
'

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
out="${here}/../../../docs/schemas/$(basename "$(dirname "$here")")"

cd "$here"
find . -name 'schema.json' | while read -r schema; do
    dest="${out}/$(dirname "${schema#./}")"
    mkdir -p "$dest"
    generate-schema-doc --config template_name=md "$schema" "${dest}/schema.md"
    generate-schema-doc --config template_name=js "$schema" "${dest}/schema.html"
    echo "$RPI_CSS" >> "${dest}/schema_doc.css"
done
