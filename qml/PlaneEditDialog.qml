pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Dialog {
    id: root
    title: "Edycja Samolotu"
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: parent
    modal: true
    width: 520

    required property var service

    property int planeId: -1
    property string brandValue: ""
    property string modelValue: ""
    property string statusValue: "Dostepny"
    property int thrustValue: 0
    property double lengthValue: 0
    property int numberOfEnginesValue: 1
    property int passengersValue: 0
    property double maxSpeedValue: 0
    property double maxAltitudeValue: 0

    signal saved()

    function openWithData(plane) {
        if (!plane) {
            return
        }

        root.planeId = plane.id
        root.brandValue = plane.brand ? plane.brand : ""
        root.modelValue = plane.model ? plane.model : ""
        root.statusValue = plane.status ? plane.status : "Dostepny"
        root.thrustValue = plane.thrust ? plane.thrust : 0
        root.lengthValue = plane.length ? plane.length : 0
        root.numberOfEnginesValue = plane.numberOfEngines ? plane.numberOfEngines : 1
        root.passengersValue = plane.passengers ? plane.passengers : 0
        root.maxSpeedValue = plane.maxSpeed ? plane.maxSpeed : 0
        root.maxAltitudeValue = plane.maxAltitude ? plane.maxAltitude : 0

        editBrandInput.text = root.brandValue
        editModelInput.text = root.modelValue

        var statusIndex = editStatusInput.model.indexOf(root.statusValue)
        editStatusInput.currentIndex = statusIndex >= 0 ? statusIndex : 0

        editThrustInput.text = String(root.thrustValue)
        editLengthInput.text = Number(root.lengthValue).toFixed(2)
        editNumberOfEnginesInput.text = String(root.numberOfEnginesValue)
        editPassengersInput.text = String(root.passengersValue)
        editMaxSpeedInput.text = Number(root.maxSpeedValue).toFixed(2)
        editMaxAltitudeInput.text = Number(root.maxAltitudeValue).toFixed(2)

        root.open()
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        padding: 15
        contentWidth: scroll.availableWidth

        ColumnLayout {
            id: editColumn
            width: scroll.availableWidth
            spacing: 10

            Label { text: "Podstawowe dane"; font.bold: true; font.pixelSize: 12; color: "#212529" }

            TextField {
                id: editBrandInput
                Layout.fillWidth: true
                font.pixelSize: 12
            }
            TextField {
                id: editModelInput
                Layout.fillWidth: true
                font.pixelSize: 12
            }
            ComboBox {
                id: editStatusInput
                model: ["Dostepny", "W serwisie"]
                Layout.fillWidth: true
                font.pixelSize: 12
            }

            Label { text: "Parametry techniczne"; font.bold: true; font.pixelSize: 12; color: "#212529"; Layout.topMargin: 8 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: "Siła ciągu (kN)"; font.pixelSize: 10 }
                    TextField {
                        id: editThrustInput
                        text: "0"
                        inputMethodHints: Qt.ImhDigitsOnly
                        Layout.fillWidth: true
                        font.pixelSize: 11
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: "Długość (m)"; font.pixelSize: 10 }
                    TextField {
                        id: editLengthInput
                        text: "0.00"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        Layout.fillWidth: true
                        font.pixelSize: 11
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: "Liczba silników"; font.pixelSize: 10 }
                    TextField {
                        id: editNumberOfEnginesInput
                        text: "1"
                        inputMethodHints: Qt.ImhDigitsOnly
                        Layout.fillWidth: true
                        font.pixelSize: 11
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: "Pasażerowie"; font.pixelSize: 10 }
                    TextField {
                        id: editPassengersInput
                        text: "0"
                        inputMethodHints: Qt.ImhDigitsOnly
                        Layout.fillWidth: true
                        font.pixelSize: 11
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: "Max prędkość (km/h)"; font.pixelSize: 10 }
                    TextField {
                        id: editMaxSpeedInput
                        text: "0.00"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        Layout.fillWidth: true
                        font.pixelSize: 11
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: "Max wysokość (km)"; font.pixelSize: 10 }
                    TextField {
                        id: editMaxAltitudeInput
                        text: "0.00"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        Layout.fillWidth: true
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    onAccepted: {
        var brandToSave = editBrandInput.text.length > 0 ? editBrandInput.text : root.brandValue
        var modelToSave = editModelInput.text.length > 0 ? editModelInput.text : root.modelValue
        var thrustVal = parseInt(editThrustInput.text) || 0
        var lengthVal = parseFloat(editLengthInput.text) || 0
        var enginesVal = parseInt(editNumberOfEnginesInput.text) || 1
        var passengersVal = parseInt(editPassengersInput.text) || 0
        var speedVal = parseFloat(editMaxSpeedInput.text) || 0
        var altitudeVal = parseFloat(editMaxAltitudeInput.text) || 0

        if (root.service.updatePlane(root.planeId, brandToSave, modelToSave, editStatusInput.currentText,
                                     thrustVal, lengthVal, enginesVal, passengersVal, speedVal, altitudeVal, "")) {
            root.saved()
        }
    }
}
