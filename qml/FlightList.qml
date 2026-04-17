pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "flightView"
    property int editFlightId: -1
    property int editPlaneIdValue: -1
    property int editDepAirportIdValue: -1
    property int editArrAirportIdValue: -1
    property string editStartValue: ""
    property string editEndValue: ""
    property var pickerTargetField: null
    property date pickerSelectedDate: new Date()
    property string flightFormErrorMessage: ""

    // qmllint disable unqualified
    readonly property var service: flightService 
    // qmllint enable unqualified

    // Funkcja odswiezajaca glowna liste lotow
    function refreshFlights() {
        listView.model = root.service.getAllFlights();
    }

    // Funkcja ladujaca dane do list rozwijanych w formularzu
    function loadDropdowns() {
        // Samoloty
        // qmllint disable unqualified
        var pData = planeService.getAllPlanes();
        // qmllint enable unqualified
        var pModel = [];
        for (var i = 0; i < pData.length; i++) {
            if (pData[i].status !== "W serwisie") {
                pModel.push({ text: pData[i].brand + " " + pData[i].model, value: pData[i].id });
            }
        }
        planeCombo.model = pModel;
        editPlaneCombo.model = pModel;

        // Lotniska
        // qmllint disable unqualified
        var aData = airportService.getAllAirports();
        // qmllint enable unqualified
        var aModel = [];
        for (var j = 0; j < aData.length; j++) {
            aModel.push({ text: aData[j].icaoCode + " - " + aData[j].name, value: aData[j].id });
        }
        depCombo.model = aModel;
        arrCombo.model = aModel;
        editDepCombo.model = aModel;
        editArrCombo.model = aModel;
    }

    function findIndexByValue(modelArray, targetValue) {
        for (var i = 0; i < modelArray.length; i++) {
            if (modelArray[i].value === targetValue) {
                return i;
            }
        }
        return -1;
    }

    function toIsoDateTime(inputText) {
        var value = inputText ? inputText.trim() : "";
        if (value.length === 0) {
            return "";
        }

        // UI accepts both: "YYYY-MM-DD HH:MM" and "DD.MM.YYYY HH:MM"
        if (value.indexOf(".") >= 0) {
            var parts = value.split(" ");
            if (parts.length === 2) {
                var dateParts = parts[0].split(".");
                if (dateParts.length === 3) {
                    value = dateParts[2] + "-" + dateParts[1] + "-" + dateParts[0] + " " + parts[1];
                }
            }
        }

        if (value.indexOf("T") < 0) {
            value = value.replace(" ", "T");
        }

        if (value.length === 16) {
            value += ":00";
        }

        return value;
    }

    function formatDisplayDateTime(dateObj) {
        return Qt.formatDateTime(dateObj, "yyyy-MM-dd HH:mm");
    }

    function parseDateTimeOrFallback(inputText, fallbackDate) {
        var iso = root.toIsoDateTime(inputText);
        if (iso.length === 0) {
            return fallbackDate;
        }

        var parsed = new Date(iso);
        if (isNaN(parsed.getTime())) {
            return fallbackDate;
        }

        return parsed;
    }

    function openDateTimePicker(targetField, initialText) {
        root.pickerTargetField = targetField;
        var fallback = new Date();
        var initial = root.parseDateTimeOrFallback(initialText, fallback);

        root.pickerSelectedDate = initial;
        monthGrid.month = initial.getMonth();
        monthGrid.year = initial.getFullYear();
        hourSpin.value = initial.getHours();
        minuteSpin.value = initial.getMinutes();
        dateTimePopup.open();
    }

    function applyPickedDateTime() {
        if (!root.pickerTargetField) {
            return;
        }

        var picked = root.pickerSelectedDate;
        var composed = new Date(
            picked.getFullYear(),
            picked.getMonth(),
            picked.getDate(),
            hourSpin.value,
            minuteSpin.value,
            0
        );

        root.pickerTargetField.text = root.formatDisplayDateTime(composed);
        dateTimePopup.close();
    }

    Component.onCompleted: {
        root.refreshFlights();
        root.loadDropdowns();
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refreshFlights()
    }

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 30

        // --- Naglowek ---
        RowLayout {
            Layout.fillWidth: true
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Label {
                    text: "Harmonogram Lotów"
                    font.pixelSize: 32; font.bold: true; color: "#212529"
                }
                Label {
                    text: "Planuj trasy i zarządzaj rezerwacjami floty"
                    font.pixelSize: 15; color: "#6C757D"
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "+ Zaplanuj Lot"
                Material.background: Material.accent
                Material.foreground: "white"
                Material.elevation: 0
                font.bold: true; font.pixelSize: 14
                Layout.preferredHeight: 45
                onClicked: {
                    root.loadDropdowns(); // Odswiezamy listy przed otwarciem
                    addDialog.open();
                }
            }
        }

        // --- Lista Lotow ---
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 15

            delegate: Pane {
                id: flightDelegate
                required property var modelData
                width: listView.width - 10 
                x: (listView.width - width) / 2
                Material.background: "#FAFAFA" 
                padding: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 25

                    // Ozdobna ikona samolociku
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: "#E0F2F1" // Jasny morski
                        Label {
                            anchors.centerIn: parent
                            text: "✈" 
                            font.pixelSize: 20; color: "#009688"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label {
                            text: flightDelegate.modelData.planeName
                            font.pixelSize: 18; font.bold: true; color: "#212529"
                        }
                        Rectangle {
                            radius: 10
                            implicitHeight: 24
                            implicitWidth: statusText.implicitWidth + 20
                            color: flightDelegate.modelData.statusColor ? flightDelegate.modelData.statusColor : "#2E7D32"

                            Label {
                                id: statusText
                                anchors.centerIn: parent
                                text: flightDelegate.modelData.status ? flightDelegate.modelData.status : "Zaplanowany"
                                font.pixelSize: 12
                                font.bold: true
                                color: "white"
                            }
                        }
                        Label {
                            text: "Trasa: " + flightDelegate.modelData.depIcao + " ➔ " + flightDelegate.modelData.arrIcao
                            font.pixelSize: 14; font.bold: true; color: Material.accent
                        }
                        Label {
                            text: "Start: " + flightDelegate.modelData.startTime + " | Lądowanie: " + flightDelegate.modelData.endTime
                            font.pixelSize: 12; color: "#6C757D"
                        }
                    }


                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Anuluj Lot"
                        flat: true
                        Material.foreground: "#DC3545" 
                        Material.background: "#FFEBEE"
                        Material.elevation: 0
                        onClicked: {
                            if (root.service.deleteFlight(flightDelegate.modelData.id)) {
                                root.refreshFlights();
                            }
                        }
                    }
                    Button {
                        text: "Edytuj"
                        flat: true
                        Material.foreground: "#1976D2"
                        Material.background: "#E3F2FD"
                        Material.elevation: 0
                        onClicked: {
                            root.loadDropdowns();
                            root.editFlightId = flightDelegate.modelData.id;
                            root.editPlaneIdValue = flightDelegate.modelData.planeId;
                            root.editDepAirportIdValue = flightDelegate.modelData.depAirportId;
                            root.editArrAirportIdValue = flightDelegate.modelData.arrAirportId;
                            root.editStartValue = flightDelegate.modelData.startTime ? flightDelegate.modelData.startTime : "";
                            root.editEndValue = flightDelegate.modelData.endTime ? flightDelegate.modelData.endTime : "";

                            editStartInput.text = root.editStartValue;
                            editEndInput.text = root.editEndValue;

                            var planeIndex = root.findIndexByValue(editPlaneCombo.model, root.editPlaneIdValue);
                            editPlaneCombo.currentIndex = planeIndex >= 0 ? planeIndex : 0;

                            var depIndex = root.findIndexByValue(editDepCombo.model, root.editDepAirportIdValue);
                            editDepCombo.currentIndex = depIndex >= 0 ? depIndex : 0;

                            var arrIndex = root.findIndexByValue(editArrCombo.model, root.editArrAirportIdValue);
                            editArrCombo.currentIndex = arrIndex >= 0 ? arrIndex : 0;

                            editDialog.open();
                        }
                    }
                }
            }
        }
    }

    // --- Dialog Dodawania ---
    Dialog {
        id: addDialog
        title: "Kreator Nowego Lotu"
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 860)

        ColumnLayout {
            anchors.fill: parent
            spacing: 15
            
            Label { text: "Wybierz maszynę:"; color: "#6C757D"; font.bold: true }
            ComboBox {
                id: planeCombo
                Layout.fillWidth: true; font.pixelSize: 16
                textRole: "text"
                valueRole: "value"
            }

            Label { text: "Wybierz lotniska (Start -> Cel):"; color: "#6C757D"; font.bold: true; Layout.topMargin: 10 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                ComboBox {
                    id: depCombo
                    Layout.fillWidth: true; font.pixelSize: 14
                    textRole: "text"
                    valueRole: "value"
                }
                Label { text: "➔"; font.pixelSize: 20; color: Material.accent }
                ComboBox {
                    id: arrCombo
                    Layout.fillWidth: true; font.pixelSize: 14
                    textRole: "text"
                    valueRole: "value"
                }
            }

            Label { text: "Daty i godziny (Format: YYYY-MM-DD HH:MM):"; color: "#6C757D"; font.bold: true; Layout.topMargin: 10 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                TextField {
                    id: startInput
                    placeholderText: "Start"
                    readOnly: true
                    Layout.fillWidth: true; font.pixelSize: 14
                }
                Button {
                    text: "Wybierz"
                    onClicked: root.openDateTimePicker(startInput, startInput.text)
                }
                TextField {
                    id: endInput
                    placeholderText: "Koniec"
                    readOnly: true
                    Layout.fillWidth: true; font.pixelSize: 14
                }
                Button {
                    text: "Wybierz"
                    onClicked: root.openDateTimePicker(endInput, endInput.text)
                }
            }

            Label {
                text: root.flightFormErrorMessage
                visible: text.length > 0
                color: "#C62828"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8

                Item { Layout.fillWidth: true }

                Button {
                    text: "Anuluj"
                    flat: true
                    onClicked: addDialog.close()
                }

                Button {
                    text: "Dodaj"
                    Material.background: Material.accent
                    Material.foreground: "white"
                    onClicked: {
                        var startIso = root.toIsoDateTime(startInput.text);
                        var endIso = root.toIsoDateTime(endInput.text);

                        if (root.service.addFlight(planeCombo.currentValue, depCombo.currentValue, arrCombo.currentValue, startIso, endIso)) {
                            root.refreshFlights();
                            root.flightFormErrorMessage = "";
                            startInput.clear();
                            endInput.clear();
                            addDialog.close();
                        } else {
                            root.flightFormErrorMessage = "Samolot jest już zajęty albo znajduje się w serwisie. Wybierz inny termin lub maszynę.";
                        }
                    }
                }
            }
        }

        onOpened: {
            root.flightFormErrorMessage = ""
            if (startInput.text.length === 0) {
                startInput.text = root.formatDisplayDateTime(new Date());
            }
            if (endInput.text.length === 0) {
                var endDefault = new Date();
                endDefault.setHours(endDefault.getHours() + 2);
                endInput.text = root.formatDisplayDateTime(endDefault);
            }
        }

    }

    // --- Dialog Edycji ---
    Dialog {
        id: editDialog
        title: "Edycja Lotu"
        anchors.centerIn: parent
        modal: true
        width: Math.min(root.width - 40, 860)

        ColumnLayout {
            anchors.fill: parent
            spacing: 15

            Label { text: "Wybierz maszynę:"; color: "#6C757D"; font.bold: true }
            ComboBox {
                id: editPlaneCombo
                Layout.fillWidth: true; font.pixelSize: 16
                textRole: "text"
                valueRole: "value"
            }

            Label { text: "Wybierz lotniska (Start -> Cel):"; color: "#6C757D"; font.bold: true; Layout.topMargin: 10 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                ComboBox {
                    id: editDepCombo
                    Layout.fillWidth: true; font.pixelSize: 14
                    textRole: "text"
                    valueRole: "value"
                }
                Label { text: "➔"; font.pixelSize: 20; color: Material.accent }
                ComboBox {
                    id: editArrCombo
                    Layout.fillWidth: true; font.pixelSize: 14
                    textRole: "text"
                    valueRole: "value"
                }
            }

            Label { text: "Daty i godziny (Format: YYYY-MM-DD HH:MM):"; color: "#6C757D"; font.bold: true; Layout.topMargin: 10 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                TextField {
                    id: editStartInput
                    placeholderText: "Start"
                    readOnly: true
                    Layout.fillWidth: true; font.pixelSize: 14
                }
                Button {
                    text: "Wybierz"
                    onClicked: root.openDateTimePicker(editStartInput, editStartInput.text)
                }
                TextField {
                    id: editEndInput
                    placeholderText: "Koniec"
                    readOnly: true
                    Layout.fillWidth: true; font.pixelSize: 14
                }
                Button {
                    text: "Wybierz"
                    onClicked: root.openDateTimePicker(editEndInput, editEndInput.text)
                }
            }

            Label {
                text: root.flightFormErrorMessage
                visible: text.length > 0
                color: "#C62828"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8

                Item { Layout.fillWidth: true }

                Button {
                    text: "Anuluj"
                    flat: true
                    onClicked: editDialog.close()
                }

                Button {
                    text: "Zapisz"
                    Material.background: Material.accent
                    Material.foreground: "white"
                    onClicked: {
                        var startText = editStartInput.text.length > 0 ? editStartInput.text : root.editStartValue;
                        var endText = editEndInput.text.length > 0 ? editEndInput.text : root.editEndValue;
                        var startIso = root.toIsoDateTime(startText);
                        var endIso = root.toIsoDateTime(endText);

                        if (root.service.updateFlight(root.editFlightId,
                                                      editPlaneCombo.currentValue,
                                                      editDepCombo.currentValue,
                                                      editArrCombo.currentValue,
                                                      startIso,
                                                      endIso)) {
                            root.refreshFlights();
                            root.flightFormErrorMessage = "";
                            editStartInput.clear();
                            editEndInput.clear();
                            editDialog.close();
                        } else {
                            root.flightFormErrorMessage = "Samolot jest już zajęty albo znajduje się w serwisie. Wybierz inny termin lub maszynę.";
                        }
                    }
                }
            }
        }

        onOpened: root.flightFormErrorMessage = ""
    }

    Popup {
        id: dateTimePopup
        modal: true
        focus: true
        anchors.centerIn: parent
        width: Math.min(root.width - 30, 620)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "white"
            radius: 10
            border.color: "#E0E0E0"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 14
            anchors.bottomMargin: 50
            spacing: 10

            Label {
                text: "Wybierz date i godzine"
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true

                Button {
                    text: "<"
                    onClicked: {
                        if (monthGrid.month === 0) {
                            monthGrid.month = 11;
                            monthGrid.year = monthGrid.year - 1;
                        } else {
                            monthGrid.month = monthGrid.month - 1;
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(new Date(monthGrid.year, monthGrid.month, 1), "MMMM yyyy")
                }

                Button {
                    text: ">"
                    onClicked: {
                        if (monthGrid.month === 11) {
                            monthGrid.month = 0;
                            monthGrid.year = monthGrid.year + 1;
                        } else {
                            monthGrid.month = monthGrid.month + 1;
                        }
                    }
                }
            }

            DayOfWeekRow {
                locale: Qt.locale()
                Layout.fillWidth: true
            }

            MonthGrid {
                id: monthGrid
                Layout.fillWidth: true
                month: root.pickerSelectedDate.getMonth()
                year: root.pickerSelectedDate.getFullYear()

                delegate: Rectangle {
                    id: dayCell
                    required property var model

                    readonly property date cellDate: model.date
                    readonly property bool inCurrentMonth: cellDate.getMonth() === monthGrid.month
                    readonly property bool selectedDate: cellDate.getDate() === root.pickerSelectedDate.getDate()
                                                        && cellDate.getMonth() === root.pickerSelectedDate.getMonth()
                                                        && cellDate.getFullYear() === root.pickerSelectedDate.getFullYear()

                    implicitWidth: 38
                    implicitHeight: 32
                    radius: 16
                    color: selectedDate ? Material.accentColor : "transparent"
                    opacity: inCurrentMonth ? 1.0 : 0.45

                    Label {
                        anchors.centerIn: parent
                        text: dayCell.cellDate.getDate()
                        color: parent.selectedDate ? "white" : "#212529"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.pickerSelectedDate = new Date(dayCell.cellDate.getFullYear(), dayCell.cellDate.getMonth(), dayCell.cellDate.getDate());
                            monthGrid.month = root.pickerSelectedDate.getMonth();
                            monthGrid.year = root.pickerSelectedDate.getFullYear();
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Label {
                        text: "Godzina"
                        font.pixelSize: 12
                    }
                    SpinBox {
                        id: hourSpin
                        from: 0
                        to: 23
                        editable: true
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Label {
                        text: "Minuta"
                        font.pixelSize: 12
                    }
                    SpinBox {
                        id: minuteSpin
                        from: 0
                        to: 59
                        editable: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 20

                Item { Layout.fillWidth: true; Layout.minimumWidth: 30 }

                Button {
                    text: "Anuluj"
                    flat: true
                    Material.foreground: "#DC3545"
                    Material.background: "#FFEBEE"
                    Material.elevation: 0
                    Layout.preferredWidth: 90
                    onClicked: dateTimePopup.close()
                }
                Button {
                    text: "Dodaj"
                    flat: true
                    Material.foreground: "#1976D2"
                    Material.background: "#E3F2FD"
                    Material.elevation: 0
                    Layout.preferredWidth: 90
                    onClicked: root.applyPickedDateTime()
                }

                Item { Layout.fillWidth: true; Layout.minimumWidth: 30 }
            }
        }
    }
}