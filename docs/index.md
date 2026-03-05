# rpi-image-gen - Layer Documentation

This documentation provides comprehensive information about the available layers provided by rpi-image-gen.

## What are Layers?

Layers are modular, composable components that define specific aspects of your Raspberry Pi build. Each layer encapsulates a specific and focussed piece of functionality and can declare dependencies on other layers, creating a flexible build system. Layers have been loosely grouped into categories with a super-set being as follows.

- **Device Layers**: Hardware-specific configuration for a particular device type. For example, may only install firmware applicable to Pi5.  
- **Image Layers**: Image-specific configuration to produce an image with a defined footprint / on-disk layout. For example, an image capable of supporting AB booting for OS and system slot redundancy.  
- **General Layers**: Reusable configuration snippets, utilities, groups of related functionality, packages and/or scripts. For example, local system user account creation, basic networking, etc.
- **Suites**: A layer providing a particular baseline of device functionality. Typically, these type of 'profile' layers are agnostic to the underlying device. Using a suite allows a single layer to recursively pull in other layers to provide a common base of functionality such as a desktop or SDK, or a minimal set of userland components providing apt and networking, container utilities, etc.

## How are Layers Used?
rpi-image-gen uses custom metadata in a layer to declare variables and construct a deterministic layer build order then passes this to [**bdebstrap**](https://github.com/bdrung/bdebstrap) which aggregates and merges everything together into a configuration. That configuration is handed off to [**mmdebstrap**](https://gitlab.mister-muffin.de/josch/mmdebstrap) which is the engine that drives creation of the filesystem. By using bdebstrap, layers provide a structured way to configure and extend mmdebstrap's capabilities:

### Layer Structure
Each layer is a YAML file containing:  
**X-Env Metadata**: _Mandatory._ Layer attributes, variable declarations, dependencies  
**mmdebstrap configuration**: _Optional._ Package lists, repository mirrors, scripts  

### Build Process
1. **Parameter Assembly**: Config file, cmdline and CLI establish desired layers and environment variables
2. **Layer Resolution**: Layer dependencies determine build order
3. **Variable Expansion**: Environment variables are validated and expanded using defined rules
4. **Configuration Merging**: Layer are merged
5. **mmdebstrap Execution**: The merged configuration drives mmdebstrap to create the filesystem
6. **Processing**: Additional layer-specific scripts are executed at defined points, eg setup, essential, customize, cleanup, etc
7. **Post-Processing**: filesystem overlays, SBOM generation, image creation, hooks

### Key Benefits of Layers
- **Modularity**: Mix and match layers to create custom images
- **Reusability**: Share common configurations across different builds
- **Validation**: Built-in variable validation prevents configuration errors
- **Dependencies**: Automatic resolution of layer prerequisites
- **Customisation**: Override defaults through environment variables set via the config file

## X-Env Metadata
Layers use a custom **X-Env** metadata schema loosely based on [**DEB822**](https://repolib.readthedocs.io/en/latest/deb822-format.html) embedded in YAML comments. By using metadata fields a layer can define attributes, dependencies, and configuration variables. The metadata is parsed separately from the standard YAML content.

### Metadata Structure
X-Env metadata is contained within comment blocks:
```yaml
# METABEGIN
# X-Env-Layer-Name: This layer's name
# X-Env-Layer-Description: Brief description of what this layer does
# X-Env-Layer-Category: device
# X-Env-Layer-Requires: base-layer,required-layer
# X-Env-VarPrefix: device
# X-Env-Var-hostname: pi-${HOSTNAME_SUFFIX}
# X-Env-Var-hostname-Description: System hostname for the device
# X-Env-Var-hostname-Valid: regex:^[a-zA-Z0-9.-]+$
# X-Env-Var-hostname-Set: immediate
# METAEND

# mmdebstrap YAML configuration follows...

mmdebstrap:
  packages:
    - systemd
    - network-manager
```

### Layer Attributes
- **`X-Env-Layer-Name`**: Layer name
- **`X-Env-Layer-Description`**: Human-readable description of the layer's purpose
- **`X-Env-Layer-Category`**: Categorisation (device, image, etc.)
- **`X-Env-Layer-Version`**: Version identifier for the layer
- **`X-Env-Layer-Requires`**: Comma-separated list of required layers
- **`X-Env-Layer-Provides`**: Services or capabilities this layer provides
- **`X-Env-Layer-RequiresProvider`**: Services or capabilities this layer requires
- **`X-Env-Layer-Conflicts`**: Layers that cannot be used together with this one

### Dependencies and Providers
**X-Env-Layer-Requires**  
- Direct layer references - "I need these specific layers"  
- Concrete dependencies - Must reference actual layer names  
- Build order enforcement - Dependencies are loaded first and are pull in automatically  
Example: A device layer depends on a device base-layer because the base-layer provides mandatory settings inherited by the device layer.  
  
**X-Env-Layer-Provides / X-Env-Layer-RequiresProvider**  
- Abstract capability requirements - "I need something that provides X"  
- Service/capability contracts - Multiple layers could satisfy the requirement  
- Flexible implementation - Any layer providing the capability can fulfill it  
- Relationships - If a provider is required, only one can exist in the overall configuration  
Example: A layer requires a device provider, which could be satisfied by different device layers  

### Environment Variables
- **`X-Env-VarPrefix`**: Prefix for all variables declared by this layer (e.g., `device`)
- **`X-Env-VarRequires`**: Comma-separated list of variables this layer expects from other layers
- **`X-Env-Var-<name>`**: Variable declaration with default value (supports placeholders like `${DIRECTORY}`)
- **`X-Env-Var-<name>-Description`**: Human-readable description of the variable
- **`X-Env-Var-<name>-Valid`**: Validation rule (type, range, regex, enum, etc.)
- **`X-Env-Var-<name>-Set`**: Set policy (immediate, lazy, force, skip)

### Variable Naming Convention
Variables follow the pattern: `IGconf_<prefix>_<name>`  
- **Layer declares**: `X-Env-Var-hostname` with prefix `device`  
- **Environment variable**: `IGconf_device_hostname`  
- **Template expansion**: Can reference as `${hostname}` in YAML values  

### Placeholder Support
Variable values support dynamic placeholders:  
- **`${DIRECTORY}`**: Directory containing the layer file  
- **`${FILENAME}`**: Name of the layer file (without extension)  
- **`${FILEPATH}`**: Full path to the layer file  

## Configuration Variables

The environment variables declared by a layer customise build behavior:  
- **Validation**: Each variable includes validation rules (types, ranges, patterns)  
- **Placeholders**: Support for dynamic values like `${DIRECTORY}` and `${FILENAME}`  
- **Set Policies**: Control when and how variables are applied during layer resolution  
- **Documentation**: Integrated help and validation error messages  

For variable validation help and policy explanations, see the [Variable Validation Guide](variable-validation.html).

For detailed information about a particular layer, including configuration options and defaults, please inspect the layer via the command line (```rpi-image-gen layer --describe <layer name>```) or refer to the layer's documentation page. It is recommended to use a config file to set layer variables when building. Layers that declare variables specify a defined prefix. Use this prefix in the config file to set variables applicable to that layer. For example - device and image layers define variables with prefix 'device' and 'image' respectively:

```
[device]
storage_type=nvme

[image]
compression=zstd
```

## How to Use This Documentation

- Browse the layer list below to find layers relevant to your build
- Click on any layer name to view detailed documentation information including:
  - Configuration variables and their validation rules
  - Package dependencies and installation details
  - Layer relationships and dependencies
  - Technical implementation details

## Getting Started

1. Choose a device layer that matches your Raspberry Pi hardware
2. Choose an image layer applicable to your deployment
3. Add a suite and/or list of general layers for additional functionality
4. Configure the variables as documented in each layer
5. Run `rpi-image-gen build` with your config

---
