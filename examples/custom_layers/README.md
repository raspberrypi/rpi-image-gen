Build a system with a custom config and multiple layers, declaring dependencies between layers and defining variables.

The config file used by this example specifies a custom layer to build a system from, which uses built-in and custom layers as dependencies. The custom layers declare additional variables to the config system which are used in the layers.

Layer acme-sdk-v1.yaml uses the uchroot helper to simplify user chroot operations to ensure files are created in the user's home directory with appropriate permissions. The helper makes standard system variables available in the environment which abstracts and simplifies the operation.

```text
examples/custom_layers/
|-- acme.options
|-- config
|   `-- acme-integration.yaml
|-- layer
|   |-- acme-developer.yaml
|   |-- acme-sdk-v1.yaml
|   `-- essential.yaml
|-- profile
|   `-- deb12-acme
|-- README.md
`-- setup-functions
```

```bash
rpi-image-gen build -S ./examples/custom_layers/ -c acme-integration.yaml
```
