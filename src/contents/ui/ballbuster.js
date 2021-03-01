/*
 * SPDX-FileCopyrightText: (C) 2021 Claudio Cambra <claudio.cambra@gmail.com>
 * 
 * SPDX-LicenseRef: GPL-3.0-or-later
 */

var blockSize = Kirigami.Units.gridUnit * 2
var maxColumn = 7;
var maxRow = 9;
var maxIndex = maxColumn * maxRow;
var board = new Array(maxIndex);
var component;

function index(column, row) {
	return column + (row * maxColumn);
}

function wipeBoard() {
	for (let i = 0; i < maxIndex; i++) {
		if (board[i] != null)
			board[i].destroy();
	}
}

function createBlock(column, row) {
	if (component == null) 
		component = Qt.createComponent("Block.qml");
	
	if (component.status == Component.Ready) {
		var dynamicObject = component.createObject(background);
		if (dynamicObject == null) {
            console.log("error creating block");
            console.log(component.errorString());
            return false;
        }
        dynamicObject.x = column * blockSize;
        dynamicObject.y = row * blockSize;
        dynamicObject.width = blockSize;
        dynamicObject.height = blockSize;
        board[index(column, row)] = dynamicObject;
	} else {
        console.log("error loading block component");
        console.log(component.errorString());
        return false;
    }
    return true;
}

function startNewGame() {
	wipeBoard();
	
	board = new Array(maxIndex);
    for (var column = 0; column < maxColumn; column++) {
        for (var row = 0; row < maxRow; row++) {
            board[index(column, row)] = null;
            createBlock(column, row);
        }
    }
}
