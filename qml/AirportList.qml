pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "airportView"
    property int editAirportId: -1
    property string editIcaoValue: ""
    property string editNameValue: ""
    property string editLatValue: ""
    property string editLonValue: ""
    property string mapExtractStatus: ""
    property bool applyingSuggestion: false

    // qmllint disable unqualified
    readonly property var service: airportService 
    // qmllint enable unqualified

    // Bezposrednie ladowanie danych do modelu
    function refreshAirports() {
        listView.model = root.service.getAllAirports();
    }

    function fillFromMapsUrl(urlValue) {
        var parsed = root.service.parseGoogleMapsUrl(urlValue)
        if (parsed.ok) {
            if (parsed.name && parsed.name.length > 0) {
                nameInput.text = parsed.name
            }
            latInput.text = Number(parsed.latitude).toFixed(7)
            lonInput.text = Number(parsed.longitude).toFixed(7)
            if (parsed.icaoSuggested && parsed.icaoSuggested.length > 0) {
                icaoInput.text = parsed.icaoSuggested
                var distText = parsed.distanceKm !== undefined ? Number(parsed.distanceKm).toFixed(2) + " km" : "?"
                mapExtractStatus = "Pobrano dane z linku. Zaproponowano ICAO: " + parsed.icaoSuggested + " (" + distText + ")"
            } else {
                mapExtractStatus = "Pobrano nazwe i wspolrzedne z linku."
            }
        } else {
            mapExtractStatus = parsed.error ? parsed.error : "Nie udalo sie odczytac danych z linku."
        }
    }

    function updateNameSuggestions() {
        if (applyingSuggestion) {
            return
        }

        var query = nameInput.text
        suggestionModel.clear()
        if (!query || query.trim().length < 2) {
            suggestionPopup.visible = false
            return
        }

        var found = root.service.searchReferenceAirportsByName(query, 8)
        for (var i = 0; i < found.length; ++i) {
            suggestionModel.append(found[i])
        }
        suggestionPopup.visible = suggestionModel.count > 0
    }

    function applySuggestion(item) {
        applyingSuggestion = true
        nameInput.text = item.name
        icaoInput.text = item.icao
        latInput.text = Number(item.latitude).toFixed(7)
        lonInput.text = Number(item.longitude).toFixed(7)
        mapExtractStatus = "Ustawiono dane z podpowiedzi: " + item.icao
        suggestionPopup.visible = false
        applyingSuggestion = false
    }

    Component.onCompleted: {
        root.refreshAirports()
    }

    // Jasne tlo
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
                spacing: 5
                Label {
                    text: "Baza Lotnisk"
                    font.pixelSize: 32; font.bold: true; color: "#212529"
                }
                Label {
                    text: "Zarządzaj lokalizacjami i kodami ICAO"
                    font.pixelSize: 15; color: "#6C757D"
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "+ Dodaj Lotnisko"
                Material.background: Material.accent
                Material.foreground: "white"
                Material.elevation: 0
                font.bold: true; font.pixelSize: 14
                Layout.preferredHeight: 45
                onClicked: addDialog.open()
            }
        }

        // --- Lista Lotnisk ---
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 15

            delegate: Pane {
                id: airportDelegate
                required property var modelData
                width: listView.width - 10 
                x: (listView.width - width) / 2
                Material.background: "#FAFAFA" 
                padding: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 25

                    // Ozdobna ikona z pierwsza litera kodu ICAO
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: "#E8EAF6" // Lekki fioletowo-niebieski
                        Label {
                            anchors.centerIn: parent
                            text: airportDelegate.modelData.icaoCode ? airportDelegate.modelData.icaoCode.charAt(0) : "A"
                            font.pixelSize: 20; font.bold: true; color: "#3F51B5"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label {
                            text: airportDelegate.modelData.name
                            font.pixelSize: 18; font.bold: true; color: "#212529"
                        }
                        Label {
                            text: "Kod ICAO: " + airportDelegate.modelData.icaoCode
                            font.pixelSize: 14; font.bold: true; color: Material.accent
                        }
                        Label {
                            text: "Współrzędne: φ " + Number(airportDelegate.modelData.latitude).toFixed(4) + ", λ " + Number(airportDelegate.modelData.longitude).toFixed(4)
                            font.pixelSize: 12; color: "#ADB5BD"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Usuń"
                        flat: true
                        Material.foreground: "#DC3545" 
                        Material.background: "#FFEBEE"
                        Material.elevation: 0
                        onClicked: {
                            if (root.service.deleteAirport(airportDelegate.modelData.id)) {
                                root.refreshAirports();
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
                            root.editAirportId = airportDelegate.modelData.id
                            root.editIcaoValue = airportDelegate.modelData.icaoCode ? airportDelegate.modelData.icaoCode : ""
                            root.editNameValue = airportDelegate.modelData.name ? airportDelegate.modelData.name : ""
                            root.editLatValue = airportDelegate.modelData.latitude !== undefined ? airportDelegate.modelData.latitude.toString() : ""
                            root.editLonValue = airportDelegate.modelData.longitude !== undefined ? airportDelegate.modelData.longitude.toString() : ""
                            editIcaoInput.clear()
                            editNameInput.clear()
                            editLatInput.clear()
                            editLonInput.clear()
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
        title: "Rejestracja Nowego Lotniska"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 450

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            ListModel {
                id: suggestionModel
            }

            TextField {
                id: mapsUrlInput
                placeholderText: "Link Google Maps"
                Layout.fillWidth: true
                font.pixelSize: 15
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Pobierz dane z linku"
                    Layout.fillWidth: true
                    onClicked: root.fillFromMapsUrl(mapsUrlInput.text)
                }

                Button {
                    text: "Otworz Google Maps"
                    Layout.fillWidth: true
                    onClicked: {
                        var urlToOpen = mapsUrlInput.text.length > 0 ? mapsUrlInput.text : "https://www.google.com/maps"
                        Qt.openUrlExternally(urlToOpen)
                    }
                }
            }

            Label {
                text: root.mapExtractStatus
                visible: text.length > 0
                color: text.startsWith("Pobrano") ? "#2E7D32" : "#C62828"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 12
            }
            
            TextField {
                id: nameInput
                placeholderText: "Pełna nazwa lotniska"
                Layout.fillWidth: true; font.pixelSize: 16
                onTextChanged: root.updateNameSuggestions()
            }

            TextField {
                id: icaoInput
                placeholderText: "Kod ICAO (np. EPWA)"
                Layout.fillWidth: true; font.pixelSize: 16
                maximumLength: 4
            }

            Rectangle {
                id: suggestionPopup
                Layout.fillWidth: true
                visible: false
                color: "#FFFFFF"
                border.color: "#DADCE0"
                radius: 6
                implicitHeight: Math.min(200, suggestionList.contentHeight + 10)

                ListView {
                    id: suggestionList
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    model: suggestionModel
                    delegate: ItemDelegate {
                        required property string name
                        required property string icao
                        required property double latitude
                        required property double longitude
                        width: suggestionList.width
                        text: name + " (" + icao + ")"
                        onClicked: root.applySuggestion({
                                                           name: name,
                                                           icao: icao,
                                                           latitude: latitude,
                                                           longitude: longitude
                                                       })
                    }
                }
            }
            
            // Pola na wspolrzedne ukladamy obok siebie
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                TextField {
                    id: latInput
                    placeholderText: "Szerokość (φ)"
                    Layout.fillWidth: true; font.pixelSize: 16
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
                TextField {
                    id: lonInput
                    placeholderText: "Długość (λ)"
                    Layout.fillWidth: true; font.pixelSize: 16
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
            }
        }

        onAccepted: {
            // Konwersja tekstu z pol na liczby zmiennoprzecinkowe (float/double)
            var lat = parseFloat(latInput.text.replace(",", "."));
            var lon = parseFloat(lonInput.text.replace(",", "."));
            
            if (root.service.addAirport(icaoInput.text.toUpperCase(), nameInput.text, lat, lon)) {
                root.refreshAirports();
                icaoInput.clear();
                nameInput.clear();
                latInput.clear();
                lonInput.clear();
                mapsUrlInput.clear();
                root.mapExtractStatus = "";
                suggestionModel.clear();
                suggestionPopup.visible = false
            }
        }

        onOpened: {
            root.mapExtractStatus = ""
            suggestionModel.clear()
            suggestionPopup.visible = false
        }
    }

    // --- Dialog Edycji ---
    Dialog {
        id: editDialog
        title: "Edycja Lotniska"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 450

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            TextField {
                id: editNameInput
                placeholderText: root.editNameValue
                Layout.fillWidth: true; font.pixelSize: 16
            }

            TextField {
                id: editIcaoInput
                placeholderText: root.editIcaoValue
                Layout.fillWidth: true; font.pixelSize: 16
                maximumLength: 4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                TextField {
                    id: editLatInput
                    placeholderText: root.editLatValue
                    Layout.fillWidth: true; font.pixelSize: 16
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
                TextField {
                    id: editLonInput
                    placeholderText: root.editLonValue
                    Layout.fillWidth: true; font.pixelSize: 16
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
            }
        }

        onAccepted: {
            var icaoToSave = editIcaoInput.text.length > 0 ? editIcaoInput.text.toUpperCase() : root.editIcaoValue
            var nameToSave = editNameInput.text.length > 0 ? editNameInput.text : root.editNameValue
            var latText = editLatInput.text.length > 0 ? editLatInput.text : root.editLatValue
            var lonText = editLonInput.text.length > 0 ? editLonInput.text : root.editLonValue
            var latToSave = parseFloat(latText.replace(",", "."))
            var lonToSave = parseFloat(lonText.replace(",", "."))

            if (root.service.updateAirport(root.editAirportId, icaoToSave, nameToSave, latToSave, lonToSave)) {
                root.refreshAirports();
                editIcaoInput.clear();
                editNameInput.clear();
                editLatInput.clear();
                editLonInput.clear();
            }
        }
    }
}