#       g4bl-setup.sh - setup PATH to use this instance of G4beamline
#
#       USAGE: source ...path.../g4bl-setup.sh
#       ...path... can be absolute or relative.

G4BL_DIR="$(dirname "${BASH_SOURCE[0]}")"
G4BL_DIR="$(\cd "$G4BL_DIR" >&- 2>&- && pwd)"
G4BL_DIR="$(dirname "$G4BL_DIR")"
echo "G4beamline is in '$G4BL_DIR'"

if [ -r "$G4BL_DIR/bin" ];
then
	export PATH="$G4BL_DIR/bin:$PATH"
elif [ -r "$G4BL_DIR/MacOS" ];
then
	export PATH="$G4BL_DIR/MacOS:$PATH"
else
	echo "G4beamline programs not found"
fi

unset G4BL_DIR
