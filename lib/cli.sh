#!/bin/bash


cli_help()
{
cat <<-EOF >&2

Raspberry Pi filesystem and image generation utility.

Usage:
  $(basename $(readlink -f "$0")) [cmd] [options]
  $(basename $(readlink -f "$0")) -h|--help

Supported commands:
  help                Show this help message
  build    [options]    Filesystem and image construction
  clean    [options]    Clean work tree
  layer    [options]    Layer operations (delegated)
  metadata [options]    Layer metadata operations (delegated)
  config   [options]    Config file operations (delegated)

Delegated commands are processed by the core engine helper (bin/ig).

For command-specific help, use: $(basename $(readlink -f "$0")) <cmd> -h
EOF
}


cli_help_build()
{
cat <<-EOF >&2
Usage
  $(basename $(readlink -f "$0")) build [options] [-- key=value ...]

Options:
  [-c <config>]    Path to config file.
  [-S <src dir>]   Directory holding custom sources of config, profile, image
                   layout and layers.
  [-B <build dir>] Use this as the root directory for generation and build.
                   Sets IGconf_sys_workroot.
  [-I]             Interactive. Prompt at different stages.

  Developer Options
  [-f]             setup, build filesystem, skip image generation.
  [-i]             setup, skip building filesystem, generate image(s).

  Variable Overrides:
    Use -- to separate options from overrides.
    Any number of key=value pairs can be provided.
    Use single quotes to enable variable expansion.
EOF
}


cli_help_clean()
{
cat <<-EOF >&2
Usage
  $(basename $(readlink -f "$0")) clean [options]

Options:
  [-c <config>]    Path to config file.
  [-B <build dir>] The top level build dir to run clean operations in.
EOF
}


cli_help_layer()
{
cat <<-EOF >&2
Usage
  $(basename $(readlink -f "$0")) layer [options] ...

Options:
  [-S <src dir>]   Directory holding custom sources of config, profile, image
                   layout and layers.
  <...>            All other arguments are passed through.

  This is a delegated command, meaning that it passes all other args straight
  through to the engine for processing. Use -h to see available options.


EOF
}


cli_help_metadata()
{
cat <<-EOF >&2
Usage
  $(basename $(readlink -f "$0")) metadata [options] ...

  This is a delegated command, meaning that it passes all args straight
  through to the engine for processing. Use -h to see available options.

EOF
}


cli_help_config()
{
cat <<-EOF >&2
Usage
  $(basename $(readlink -f "$0")) config [options] ...

  This is a delegated command, meaning that it passes all args straight
  through to the engine for processing. Use -h to see available options.

EOF
}
