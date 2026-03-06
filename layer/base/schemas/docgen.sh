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

find . -name 'schema.json' | while read -r schema; do
    dir="$(dirname "$schema")"
    generate-schema-doc --config template_name=md "$schema" "${dir}/schema.md"
    generate-schema-doc --config template_name=js "$schema" "${dir}/schema.html"
    echo "$RPI_CSS" >> "${dir}/schema_doc.css"
done
