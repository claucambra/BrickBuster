/*
 * SPDX-FileCopyrightText: (C) 2021 Claudio Cambra <claudio.cambra@gmail.com>
 * 
 * SPDX-LicenseRef: GPL-3.0-or-later
 */

import QtQuick 2.1
import QtQuick.Layouts 1.2

Item {
	id: block
	Rectangle {
		id: interior
		anchors.fill: parent
		Layout.fillWidth: true
		Layout.fillHeight: true
		color: "red"
	}
}
