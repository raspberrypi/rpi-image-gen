# APT Source Templates

These files are DEB822 format `.sources` files for use as mmdebstrap mirror specifications in layer YAML files. Some are static and can be used as-is. Others are dynamic (eg contain placeholders) and must be rendered before use.

If a template contains an `X-IG-Signed-By:` field, this names the keyring that should sign the repository.
