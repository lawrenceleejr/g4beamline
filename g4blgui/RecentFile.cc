//	RecentFile.cc

#include <QAction>

#include "RecentFile.h"
#include "G4blGuiWindow.h"

RecentFile::RecentFile(G4blGuiWindow *_window, QMenu *_menu) :
			window(_window), menu(_menu), recentList(), settings(0)
{
	settings = new QSettings("muonsinc","g4blgui");
	recentList = settings->value("RecentFiles").toStringList();
	fileOpened(QString());
	connect(menu,SIGNAL(triggered(QAction*)),
					this,SLOT(openRecentFile(QAction*)));
}

void RecentFile::fileOpened(QString filename)
{
	if(!filename.isEmpty()) {
		if(!recentList.isEmpty() && filename == recentList.first())
			return;
		int j = recentList.indexOf(filename);
		if(j >= 0) recentList.removeAt(j);
		recentList.prepend(filename);
		while(recentList.size() > MAXRECENT)
			recentList.removeLast();
		settings->setValue("RecentFiles",recentList);
		settings->sync();
	}
	menu->clear();
	for(int i=0; i<recentList.size(); ++i) {
		menu->addAction(recentList[i]);
	}
}

void RecentFile::openRecentFile(QAction *action)
{
	QString f = action->text();
	if(f.isEmpty()) return;
	window->openFile(f); // calls our fileOpened()
}
