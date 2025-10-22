#!/bin/bash

# activate_bdebstrap_venv
# Adds the bdebstrap venv to PATH if it exists
activate_bdebstrap_venv()
{
	local venv_path="/opt/rpi-image-gen/bdebstrap-venv"
	if [[ -d "${venv_path}/bin" ]]; then
		export PATH="${venv_path}/bin:${PATH}"
	fi
}

# Call this automatically when sourcing this file
activate_bdebstrap_venv

# dependencies_check
# $@	Dependency files to check
#
# Each dependency is in the form of a tool to test for, optionally followed by
# a : and the name of a package if the package on a Debian-ish system is not
# named for the tool (i.e., qemu-user-static).
dependencies_check()
{
	local depfile deps missing=() op=$1

	if [[ "$op" == install ]] ; then
		shift 1
	fi

	for depfile in "$@"; do
		if [[ -e "$depfile" ]]; then
			mapfile -t dep_lines < <(grep -v '^[[:space:]]*#' "$depfile" | grep -v '^[[:space:]]*$')
			deps="${dep_lines[*]}"
		fi
		for dep in $deps; do
			if ! hash "${dep%:*}" 2>/dev/null; then
				if ! dpkg -s "${dep#*:}" > /dev/null 2>&1; then
					missing+=("${dep#*:}")
				fi
			fi
		done
	done

	if [[ "${missing[*]}" ]]; then
		echo "Required dependencies not installed"
		echo
		echo "This can be resolved on Debian systems by installing:"
		echo "${missing[@]}"
		echo
		echo "Script install_deps.sh can be used for this purpose."
		echo

		if [[ "$op" == install ]] ; then
			apt install -y "${missing[@]}"
		else
			exit 1
		fi
	fi

    # If we're building on a native arm platform, we don't need to check for
    # binfmt_misc or require it to be loaded.

	binfmt_misc_required=1

	case $(uname -m) in
		aarch64)
			binfmt_misc_required=0
			;;
		arm*)
			binfmt_misc_required=0
			;;
	esac

	if [[ "${binfmt_misc_required}" == "1" ]]; then
		if ! grep -q "/proc/sys/fs/binfmt_misc" /proc/mounts; then
			echo "Module binfmt_misc not loaded in host"
			echo "Please run:"
			echo "  sudo modprobe binfmt_misc"
			exit 1
		fi
	fi
}


install_bdebstrap_from_source()
{
	local venv_path="/opt/rpi-image-gen/bdebstrap-venv"
	
	echo "Installing bdebstrap from source to venv..."
	
	# Check if venv already exists and has bdebstrap
	if [[ -f "${venv_path}/bin/bdebstrap" ]]; then
		echo "bdebstrap venv already exists at ${venv_path}, skipping installation"
		return 0
	fi
	
	# Install dependencies for venv, git, and building bdebstrap
	apt install -y git python3 python3-venv python3-pip pandoc
	
	# Create directory and venv with system site packages access
	mkdir -p "$(dirname "${venv_path}")"
	echo "Creating Python virtual environment at ${venv_path}..."
	python3 -m venv --system-site-packages "${venv_path}"
	
	# Clone bdebstrap repository
	local temp_dir=$(mktemp -d)
	cd "$temp_dir"
	
	echo "Cloning bdebstrap repository..."
	git clone https://github.com/bdrung/bdebstrap.git
	cd bdebstrap
	
	# Install bdebstrap into venv using pip
	echo "Installing bdebstrap into venv..."
	"${venv_path}/bin/pip" install --upgrade pip
	"${venv_path}/bin/pip" install .
	
	# Create symlink for hooks in the location bdebstrap expects
	# bdebstrap calculates HOOKS_DIR as: Path(__file__).parent.parent / "share" / "bdebstrap" / "hooks"
	# So for /opt/rpi-image-gen/bdebstrap-venv/bin/bdebstrap it expects /opt/rpi-image-gen/bdebstrap-venv/share/bdebstrap/hooks
	local expected_hooks="${venv_path}/share/bdebstrap"
	local actual_hooks=$(find "${venv_path}/lib" -type d -path "*/usr/share/bdebstrap" 2>/dev/null | head -n1)
	
	if [[ -n "${actual_hooks}" && -d "${actual_hooks}" ]]; then
		echo "Creating hooks symlink at expected location..."
		mkdir -p "${venv_path}/share"
		ln -sf "${actual_hooks}" "${expected_hooks}"
	else
		>&2 echo "WARNING: Could not find bdebstrap hooks directory"
	fi
	
	# Clean up
	cd /
	rm -rf "$temp_dir"
	
	# Verify installation
	if [[ -f "${venv_path}/bin/bdebstrap" ]]; then
		echo "bdebstrap successfully installed to ${venv_path}"
	else
		>&2 echo "ERROR: bdebstrap installation failed"
		exit 1
	fi
}

dependencies_install()
{
	if [ "$(id -u)" != "0" ]; then
		>&2 echo "Please run as root to install dependencies."; exit 1
	fi
	
	# Build and install bdebstrap from source first
	install_bdebstrap_from_source
	
	dependencies_check install "$@"
}
