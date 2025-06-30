                             G4beamline 3.08
                              by Tom Roberts
               Copyright (C) 2003-2022 by Tom Roberts, Muons, Inc.
                             All rights reserved.

                       http://g4beamline.muonsinc.com


LICENSE
-------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

    http://www.gnu.org/copyleft/gpl.html

NOTE: This program uses several open-source libraries. Their license terms
can be found in the Acknowledgements section of G4beamlineUsersGuide.pdf 
(in the doc directory of the distribution).


GENERAL
-------

The general reference for G4beamline is the User's Guide, located in the
doc directory named G4beamlineUsersGuide.pdf.

It is also available on the web: http://g4beamline.muonsinc.com


INSTALLATION
------------

There is a "Quick Start" section in the User's Guide.


INSTALLING THE REQUIRED GEANT4 DATA FILES
-----------------------------------------

G4beamline uses Geant4 to perform most of the physics. It inherently needs
data files to drive and control its many physics processes.

To install the data files, run the "g4bldata" program (in the bin directory
under the install directory). It is a GUI program that lets you select which
datasets to download (depends on which physics lists you intend to use).
Note that by default it puts these data files into $HOME/Geant4Data (on
Windows C:\Geant4Data). The other programs look for it there, and if it is
not found they will run g4bldata for you. Alternatively, you can put a file
".data" into the top-level install directory, containing the full path to the
directory containing the Geant4 data files.


INITIAL TESTING
---------------

NOTE: Root requires the C++ compiler be installed during execution (not just 
build). If you don't use format=root NTuples, you do not need to install the
C++ compiler.

GUI: run the g4blgui program. Click the menu item Tools/DoRegressionTests.

Command-Line: run the g4bltest program (in the bin directory under the install
directory).

Both of these run 113 regression tests. They should all pass, though often
some are omitted (depends on configuration).


RUNNING THE PROGRAM -- GUI
--------------------------

Simply double-click the G4beamline icon. On Windows it is placed on your desktop
and in the Start/G4beamline menu. On Mac OS X it is placed where you dragged 
(copied) it when you installed it. On Linux the bin/g4bl-icon script will create
one on your desktop.

To run the GUI program via the command line:
	source G4beamline-VERSION/bin/g4bl-setup.sh
	# optionally cd where your input file is located
	g4blgui  [input.file]
This requires the X-Windows display on Linux, nothing special on Mac and
Windows. Its opening screen decribes how to use it and gives help on all
G4beamline commands..

To run the examples, simply push the Browse button, or the File/Open menu item,
navigate to the install directory / examples, and select Example1.g4bl (or 
other *.g4bl file).  Then select the desired viewer (if any), and push the 
Run button.  On Windows, a copy of "G4beamline Examples" is put into
"Documents".


RUNNING THE PROGRAM -- COMMAND-LINE
-----------------------------------

For command-line use (Linux, Mac OS X, and Windows with Cygwin), you must
add G4beamline's bin directory to your PATH:
	source G4beamline-VERSION/bin/g4bl-setup.sh
You can put this into $HOME/.bash_profile. There is also g4bl-setup.csh.

Then cd to whatever directory you plan to use for developing your
simulation(s), and execute:
	g4bl -

After a few seconds it should type (with obvious variations):
    G4BL_DIR=/Users/g4bl/G4beamline-3.08.app/Contents
    LD_LIBRARY_PATH='/Users/g4bl/G4beamline-3.08.app/Contents/lib:'
    G4ABLADATA=/Users/tjrob/Geant4Data/G4ABLA3.1
    G4LEDATA=/Users/tjrob/Geant4Data/G4EMLOW8.0
    G4ENSDFSTATEDATA=/Users/tjrob/Geant4Data/G4ENSDFSTATE2.3
    G4INCLDATA=/Users/tjrob/Geant4Data/G4INCL1.0
    G4NEUTRONHPDATA=/Users/tjrob/Geant4Data/G4NDL4.6
    G4PARTICLEXSDATA=/Users/tjrob/Geant4Data/G4PARTICLEXS4.0
    G4PIIDATA=/Users/tjrob/Geant4Data/G4PII1.3
    G4LEVELGAMMADATA=/Users/tjrob/Geant4Data/PhotonEvaporation5.7
    G4RADIOACTIVEDATA=/Users/tjrob/Geant4Data/RadioactiveDecay5.6
    G4REALSURFACEDATA=/Users/tjrob/Geant4Data/RealSurface2.2
    G4SAIDXSDATA=/Users/tjrob/Geant4Data/G4SAIDDATA2.0
    G4TENDLDATA=/Users/tjrob/Geant4Data/G4TENDL1.4
    G4LENDDATA=/Users/tjrob/Geant4Data/LEND_GND1.3_ENDF.BVII.1
    G4beamline Process ID 5737
    
    *************************************************************
     g4beamline version: 3.08                        (Aug  9 2022)
                          Copyright : Tom Roberts, Muons, Inc.
                            License : Gnu Public License
                                WWW : http://g4beamline.muonsinc.com
    
              ################################
              !!! G4Backtrace is activated !!!
              ################################
    
    
    **************************************************************
     Geant4 version Name: geant4-11-00-patch-02 [MT]   (25-May-2022)
                           Copyright : Geant4 Collaboration
                          References : NIM A 506 (2003), 250-303
                                     : IEEE-TNS 53 (2006), 270-278
                                     : NIM A 835 (2016), 186-225
                                 WWW : http://geant4.org/
    **************************************************************
    
    geometry                   nPoints=100 printGeometry=0 visual=0
                               tolerance=0.002
    cmd:


The program is now ready for input. Type "help" to get a short list of
the input-file commands, "help beam" to get help on the beam comand, or 
"help *" for a detailed description of all commands. This is a useful way
to get help on commands when editing your input file(s). Type ^C to exit
back to a shell prompt.


EXAMPLE 1
---------

The first example input file is Example1.g4bl. It is a simple file to track
muons through 1-meter drift spaces into 4 detectors. To visualize its
geometry using the Qt viewer, execute:
	cd G4beamline-VERSION/examples
	g4bl Example1.g4bl viewer=best

To run the beam through the geometry, execute:
	g4bl Example1.g4bl 
This will generate a Root file named g4beamline.root. To view it do:
	allplot g4beamline.root


OTHER EXAMPLES
--------------

There are other examples in the examples directory.
