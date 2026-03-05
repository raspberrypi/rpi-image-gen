Build a system using an in-tree configuration as a reference, and specifying particular options and overrides:

Parameters can be provided in the config file or overridden/provided via the command line.

```bash
examples/setoptions/
|-- config
|   `-- my.yaml
`-- README.md
```

```bash
rpi-image-gen build -S ./examples/setoptions -c my.yaml -- IGconf_deploy_scope=prod
```

Running interactively will allow inspection of custom variables, e.g.

```bash
rpi-image-gen build -S ./examples/setoptions -c my.yaml -I -- IGconf_deploy_scope=prod
```
