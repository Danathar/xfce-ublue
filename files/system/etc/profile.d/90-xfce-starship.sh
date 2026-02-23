# shellcheck shell=sh
# Skip cleanly if starship is unavailable for any reason.
command -v starship >/dev/null 2>&1 || return 0

# Default to a system config when the user has not defined one.
if [ -z "${STARSHIP_CONFIG:-}" ] && [ -n "${HOME:-}" ] && [ ! -f "${HOME}/.config/starship.toml" ] && [ -f /etc/starship.toml ]; then
  export STARSHIP_CONFIG=/etc/starship.toml
fi

# Initialize only for bash; other shells can define their own init path.
shell_name="$(basename "$(readlink /proc/$$/exe)")"
if [ "$shell_name" = "bash" ]; then
  eval "$(starship init bash)"
fi
unset shell_name
