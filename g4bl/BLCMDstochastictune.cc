//BLCMDstochastictune.cc
/*
This source file is part of G4beamline, http://g4beamline.muonsinc.com
Copyright (C) 2002-2013 by Tom Roberts, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

http://www.gnu.org/copyleft/gpl.html
*/

/*
 * BLCMDstochastictune -- stochastic ensemble tune particle
 *
 * Fires nEnsemble copies of the tune particle with stochastics ENABLED
 * (ionisation straggling, multiple scattering, etc.) so that each RF
 * cavity can average its timing estimate over the ensemble rather than
 * relying on a single deterministic particle.
 *
 * The normal "reference" command (with its deterministic tune particle)
 * must also be present; it runs first and provides the initial timing
 * estimate.  This command then fires nEnsemble additional particles and
 * the cavities replace their timeOffset with the ensemble average.
 *
 * Usage:
 *   stochastictune particle=mu+ referenceMomentum=200 nEnsemble=20
 */

#include <stdio.h>
#include <vector>

#include "G4RunManager.hh"
#include "G4Track.hh"
#include "G4ParticleGun.hh"
#include "G4ParticleTable.hh"

#include "BLManager.hh"
#include "BLBeam.hh"
#include "BLParam.hh"
#include "BLGroup.hh"
#include "BLCoordinates.hh"
#include "BLGlobalField.hh"

const G4double ST_UNDEFINED = -3.7e21;

/**class BLCMDstochastictune implements the stochastictune command.
 *
 *Fires nEnsemble copies of the tune particle with stochastics on.
 **/
class BLCMDstochastictune : public BLBeam, public BLCommand {
G4String particle;
G4double referenceMomentum;
G4double beamX;
G4double beamY;
G4double beamZ;
G4double beamT;
G4double beamXp;
G4double beamYp;
G4String rotation;
G4int nEnsemble;
G4int trackID;
G4RotationMatrix *rotationMatrix;
G4ThreeVector position;
G4ParticleGun *particleGun;
G4ParticleDefinition *particleDefinition;
/// Counter of ensemble particles generated so far in this run.
G4int callCount;
public:
/// Constructor.
BLCMDstochastictune();

/// copy constructor
BLCMDstochastictune(BLCMDstochastictune &r);

/// commandName() returns "stochastictune".
virtual G4String commandName() { return "stochastictune"; }

/// command() implements the stochastictune command.
virtual int command(BLArgumentVector& argv, BLArgumentMap& namedArgs);

/// defineNamedArgs() defines the named arguments for this command.
virtual void defineNamedArgs();

/// getNEvents() returns the # events to process.
virtual int getNEvents() const { return nEnsemble; }

/// init() will initialize internal variables.
virtual void init();

/// generateReferenceParticle() generates one ensemble particle.
/// Returns true while callCount < nEnsemble; false afterwards so
/// BLManager advances to the next entry in stochasticTuneVector.
virtual bool generateReferenceParticle(G4Event *event);

/// nextBeamEvent() -- not used for stochastic tune particles.
virtual bool nextBeamEvent(G4Event *event) { return false; }

/// summary() -- nothing to summarize.
virtual void summary() { }
};

BLCMDstochastictune defineStochasticTune;

BLCMDstochastictune::BLCMDstochastictune() : BLBeam(), BLCommand(),
particle(), rotation(), position()
{
registerCommand(BLCMDTYPE_BEAM);
setSynopsis("Define a stochastic ensemble tune particle.");
setDescription("Fires nEnsemble copies of the tune particle with "
"stochastics enabled (ionisation straggling, multiple "
"scattering, etc.).  Each RF cavity accumulates the timing "
"value it would assign for each ensemble member and then uses "
"the ensemble average as its final time offset.\n\n"
"This command must appear after at least one 'reference' "
"command in the input file.  The normal 'reference' tune "
"particle still runs first (with stochastics off) to provide "
"an initial estimate; the ensemble then refines it.\n\n"
"All coordinates are centerline coordinates.\n\n"
"This command is not placed into the geometry.");

particle = "mu+";
referenceMomentum = ST_UNDEFINED;
beamX = 0.0;
beamY = 0.0;
beamZ = 0.0;
beamT = 0.0;
beamXp = 0.0;
beamYp = 0.0;
nEnsemble = 10;
trackID = -100;
rotationMatrix = 0;
particleDefinition = 0;
particleGun = 0;
callCount = 0;
}

BLCMDstochastictune::BLCMDstochastictune(BLCMDstochastictune &r) :
BLBeam(), BLCommand(), particle(), rotation(), position()
{
particle = r.particle;
referenceMomentum = r.referenceMomentum;
beamX = r.beamX;
beamY = r.beamY;
beamZ = r.beamZ;
beamT = r.beamT;
beamXp = r.beamXp;
beamYp = r.beamYp;
nEnsemble = r.nEnsemble;
trackID = r.trackID;
rotationMatrix = 0;
particleDefinition = 0;
particleGun = 0;
callCount = 0;
}

int BLCMDstochastictune::command(BLArgumentVector& argv,
BLArgumentMap& namedArgs)
{
BLCMDstochastictune *b = new BLCMDstochastictune(*this);

b->rotation = "";
int retval = b->handleNamedArgs(namedArgs);

if(b->referenceMomentum == ST_UNDEFINED)
printError("stochastictune: error - need referenceMomentum");

if(b->rotation != "") {
b->rotationMatrix = stringToRotationMatrix(b->rotation);
} else {
b->rotationMatrix = new G4RotationMatrix();
}
// order is backward because (C R C^-1) C = C R
*b->rotationMatrix = *BLCoordinates::getCurrentRotation() *
*b->rotationMatrix;
G4ThreeVector local(b->beamX, b->beamY, b->beamZ);
BLCoordinates::getCurrentGlobal(local, b->position);

// ensure the beam position is within the world
BLGroup::getWorld()->setMinWidth(fabs(b->position[0])*2.0);
BLGroup::getWorld()->setMinHeight(fabs(b->position[1])*2.0);
BLGroup::getWorld()->setMinLength(fabs(b->position[2])*2.0);

BLManager::getObject()->registerStochasticTuneParticle(b);

b->print("");

return retval;
}

void BLCMDstochastictune::defineNamedArgs()
{
argString(particle,"particle","Particle name (default: mu+)");
argDouble(beamX,"beamX","Reference location in X (mm)");
argDouble(beamY,"beamY","Reference location in Y (mm)");
argDouble(beamZ,"beamZ","Reference location in Z (mm)");
argDouble(beamT,"beamT","Reference time (ns)");
argString(rotation,"rotation","Rotation of the beam");
argDouble(referenceMomentum,"referenceMomentum",
"Reference particle momentum (MeV/c)", MeV);
argDouble(beamXp,"beamXp","Reference particle Xp (radians)");
argDouble(beamYp,"beamYp","Reference particle Yp (radians)");
argDouble(referenceMomentum,"meanMomentum",
"Synonym for referenceMomentum", MeV);
argDouble(beamXp,"meanXp","Synonym for beamXp.");
argDouble(beamYp,"meanYp","Synonym for beamYp.");
argDouble(referenceMomentum,"P","Synonym for referenceMomentum", MeV);
argInt(nEnsemble,"nEnsemble",
"Number of ensemble particles to track (default: 10)");
}

void BLCMDstochastictune::init()
{
if(particleDefinition != 0) return;

particleDefinition =
G4ParticleTable::GetParticleTable()->FindParticle(particle);
if(!particleDefinition)
G4Exception("stochastictune command","UnknownParticle",
FatalException,"Unknown particle type");
particleGun = new G4ParticleGun(1);
particleGun->SetParticleDefinition(particleDefinition);
}

bool BLCMDstochastictune::generateReferenceParticle(G4Event *event)
{
if(callCount >= nEnsemble) {
// All ensemble particles have been generated; reset the counter
// for future calls and signal exhaustion to BLManager.
callCount = 0;
return false;
}

G4double mass = particleDefinition->GetPDGMass();
G4double ke = sqrt(referenceMomentum*referenceMomentum + mass*mass)
- mass;
G4ThreeVector dir;
dir[0] = beamXp;
dir[1] = beamYp;
dir[2] = 1.0/sqrt(1.0 + dir[0]*dir[0] + dir[1]*dir[1]);
dir[0] *= dir[2];
dir[1] *= dir[2];
if(rotationMatrix)
dir = *rotationMatrix * dir;

particleGun->SetParticleTime(beamT);
particleGun->SetParticleEnergy(ke);
particleGun->SetParticleMomentumDirection(dir);
particleGun->SetParticlePosition(position);
particleGun->GeneratePrimaryVertex(event);

// Use a unique, deterministic-but-varied seed per ensemble particle
// so that each sees a different stochastic outcome.  evid<0 means
// "reference-like" seeding.
G4int evid = trackID - callCount;
setRandomSeedToTrack(evid);

BLManager::getObject()->setPrimaryTrackID(1, 0);
BLManager::getObject()->clearTrackIDMap();
BLManager::getObject()->setNextSecondaryTrackID(1000);

++callCount;
printf("stochastictune: firing ensemble particle %d/%d\n",
callCount, nEnsemble);

return true;
}
