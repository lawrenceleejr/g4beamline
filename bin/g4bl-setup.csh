#	g4bl-setup.csh - setup PATH to use this instance of G4beamline
#
#	USAGE: source ...path.../g4bl-setup.csh
#	...path... can be absolute or relative.

set called=($_)
set G4BL_DIR=`dirname $called[2]`
set G4BL_DIR=`cd $G4BL_DIR; pwd`
set G4BL_DIR=`dirname $G4BL_DIR`
echo "G4beamline is in $G4BL_DIR"

if ( -r "$G4BL_DIR/bin" ) then
	setenv PATH "$G4BL_DIR/bin:$PATH"
else if ( -r "$G4BL_DIR/MacOS" ) then
	setenv PATH "$G4BL_DIR/MacOS:$PATH"
else
	echo "G4beamline programs not found"
endif

unset called G4BL_DIR
