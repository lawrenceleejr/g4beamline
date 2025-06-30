//	Geant4Data.cc

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "Geant4Data.hh"
#include "Util.hh"

#ifdef __APPLE__
#define BIN "MacOS"
#else
#define BIN "bin"
#endif

// baseURL ends with '/'
// download URL is baseURL+defs[i].name+".tar.gz"
std::string Geant4Data::baseURL = "http://muonsinc.com/Geant4Data-3.08/";

/// These are the datasets for Geant4-v11.0.2
static Geant4Data defs[] = {
 // env, name, dir, dl_size disk_size, required
 {"G4ABLADATA",       "G4ABLA.3.1",              "G4ABLA3.1",                107286,    "1.1M", false},
 {"G4LEDATA",         "G4EMLOW.8.0",             "G4EMLOW8.0",               326834565, "633M", true},
 {"G4ENSDFSTATEDATA", "G4ENSDFSTATE.2.3",        "G4ENSDFSTATE2.3",          290745,    "1.7M", true},
 {"G4INCLDATA",       "G4INCL.1.0",              "G4INCL1.0",                95840,     "0.2M", false},
 {"G4NEUTRONHPDATA",  "G4NDL.4.6",               "G4NDL4.6",                 599862135, "626M", false},
 {"G4PARTICLEXSDATA", "G4PARTICLEXS.4.0",        "G4PARTICLEXS4.0",          12242648,  "36M",  true},
 {"G4PIIDATA",        "G4PII.1.3",               "G4PII1.3",                 4293607,   "24M",  false},
 {"G4LEVELGAMMADATA", "G4PhotonEvaporation.5.7", "PhotonEvaporation5.7",     10089240,  "44M",  true},
 {"G4RADIOACTIVEDATA","G4RadioactiveDecay.5.6",  "RadioactiveDecay5.6",      1059792,   "14M",  true},
 {"G4REALSURFACEDATA","G4RealSurface.2.2",       "RealSurface2.2",           132506346, "127M", false},
 {"G4SAIDXSDATA",     "G4SAIDDATA.2.0",          "G4SAIDDATA2.0",            38502,     "0.2M", false},
 {"G4TENDLDATA",      "G4TENDL.1.4",             "G4TENDL1.4",               912261874, "888M", false},
 {"G4LENDDATA",       "LEND_GND1.3_ENDF.BVII.1", "LEND_GND1.3_ENDF.BVII.1",  900925783, "2.6G", false},
 {"", "", "", 0, "", false}
};

bool Geant4Data::setup(bool overwriteEnv)
{
	std::vector<Geant4Data> data = list();
	if(data.size() == 0) return false;
	std::string dir = directory();

	bool retval = true;
	for(std::vector<Geant4Data>::iterator i=data.begin(); i!=data.end(); ++i) {
		// check if environment variable already set
		if(overwriteEnv || getenv(i->env.c_str()) == 0) {
			// check if dir exists
			std::string d = dir + "/" + i->dir;
			struct stat info;
			if(stat(d.c_str(),&info) == 0) {
				const char *n = strdup(i->env.c_str());
				const char *v = strdup(d.c_str());
#ifndef WIN32
				setenv(n,v,1);
#else
				_putenv_s(n,v);
#endif
			} else if(i->required) {
				retval = false;
				fprintf(stderr,"Geant4Data: required dataset "
					"%s not found\n",i->name.c_str());
			}
		}
	}
	return retval;
}

std::string Geant4Data::directory(bool check)
{
	std::string retval("");
	std::string g4bl_dir(getG4blDir()); // exits program if not found
	struct stat info;

	// First, look for the file .data in g4bl_dir. If present
	// it contains the path to the Geant4Data directory.
	std::string dotData = g4bl_dir + "/.data";
	FILE *f = fopen(dotData.c_str(),"r");
	if(f != 0) {
		char line[1024];
		if(fgets(line,sizeof(line),f)) {
			   retval = line;
			   std::string::size_type p=retval.find_first_of("\r\n");
			   if(p != retval.npos) retval.erase(p,retval.npos);
		}
		fclose(f);
		if(check && stat(retval.c_str(),&info) != 0) 
			retval = "";
	}
	if(retval != "") return retval;

	// Second, look for Geant4Data in HOME
	if(getenv("HOME") != 0) {
		retval = getenv("HOME");
		retval += "/Geant4Data";
		if(check && stat(retval.c_str(),&info) != 0) 
			retval = "";
	}

#ifdef WIN32
	// Third, if not in HOME, use C:\Geant4Data
	if(retval == "" || (retval != "" && stat(retval.c_str(),&info) != 0))  {
		retval = "C:\\Geant4Data";
		if(check && stat(retval.c_str(),&info) != 0) 
			retval = "";
	}
#endif // WIN32

	return retval;
}

std::vector<Geant4Data> Geant4Data::list()
{
	std::vector<Geant4Data> retval;

	for(Geant4Data *p=defs; p->env!=""; ++p)
		retval.push_back(*p);

	return retval;
}

void Geant4Data::printEnv()
{
	for(Geant4Data *p=defs; p->env!=""; ++p) {
		const char *name = p->env.c_str();
		const char *value = getenv(name);
		if(value)
			printf("%s=%s\n",name,value);
	}
}

void Geant4Data::runG4bldata()
{
	std::string g4bl_dir(getG4blDir()); // exits program if not found
	std::string path = "\"" + g4bl_dir + "/" BIN "/g4bldata" + "\"";
	printf("Running %s\n",path.c_str());
	system(path.c_str());
	printf("%s returns\n",path.c_str());
	// now that the data are probably there, try to find them again
	setup();
}

