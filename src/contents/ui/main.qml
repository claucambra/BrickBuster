/*
 * SPDX-FileCopyrightText: (C) 2021 Claudio Cambra <claudio.cambra@gmail.com>
 * 
 * SPDX-LicenseRef: GPL-3.0-or-later
 */

import QtQuick 2.1
import org.kde.kirigami 2.4 as Kirigami
import QtQuick.Controls 2.0 as Controls

import "ballbuster.js" as BallBuster

Kirigami.ApplicationWindow {
    id: root

    title: i18n("BallBuster")

    globalDrawer: Kirigami.GlobalDrawer {
        title: i18n("BallBuster")
        titleIcon: "applications-graphics"
        actions: [

        ]
    }

    contextDrawer: Kirigami.ContextDrawer {
        id: contextDrawer
    }

    pageStack.initialPage: mainPageComponent

    Component {
        id: mainPageComponent

        Kirigami.Page {
            title: i18n("BallBuster")

            actions {
                main: Kirigami.Action {
                    icon.name: "media-playback-start-symbolic"
                    onTriggered: BallBuster.startNewGame()
                }
            }
            Item {
				width: parent.width
				anchors {
					top: parent.top
					bottom: parent.bottom
				}
				//Rectangle {
					
					//color: "black"
				//}
			}
        }
    }
}
