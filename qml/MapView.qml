pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "mapView"

    // qmllint disable unqualified
    readonly property var service: flightService
    // qmllint enable unqualified

    property var flights: []
    property int currentFlightCount: 0
    property int upcomingFlightCount: 0
    property int finishedFlightCount: 0

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value))
    }

    function toNumber(value) {
        return Number(value)
    }

    function normalizeLongitude(longitude) {
        return (longitude + 180) / 360
    }

    function normalizeLatitude(latitude) {
        var clamped = clamp(latitude, -85.05112878, 85.05112878)
        var rad = clamped * Math.PI / 180
        var mercatorY = Math.log(Math.tan(Math.PI / 4 + rad / 2))
        return 0.5 - mercatorY / (2 * Math.PI)
    }

    function project(latitude, longitude, width, height) {
        return {
            x: normalizeLongitude(longitude) * width,
            y: normalizeLatitude(latitude) * height
        }
    }

    function flightTiming(flight) {
        var startMs = toNumber(flight.startTimeUtcMs)
        var endMs = toNumber(flight.endTimeUtcMs)
        var nowMs = Date.now()
        var totalMs = endMs - startMs
        var progress = 0
        var active = false
        var finished = false

        if (!isFinite(startMs) || !isFinite(endMs) || totalMs <= 0) {
            return {
                progress: 0,
                active: false,
                finished: false,
                upcoming: true
            }
        }

        if (nowMs <= startMs) {
            progress = 0
        } else if (nowMs >= endMs) {
            progress = 1
            finished = true
        } else {
            progress = (nowMs - startMs) / totalMs
            active = true
        }

        return {
            progress: clamp(progress, 0, 1),
            active: active,
            finished: finished,
            upcoming: !active && !finished
        }
    }

    function refreshFlights() {
        flights = root.service.getAllFlights()
        currentFlightCount = 0
        upcomingFlightCount = 0
        finishedFlightCount = 0

        for (var i = 0; i < flights.length; ++i) {
            var timing = flightTiming(flights[i])
            if (timing.active) {
                currentFlightCount += 1
            } else if (timing.finished) {
                finishedFlightCount += 1
            } else {
                upcomingFlightCount += 1
            }
        }

        mapCanvas.requestPaint()
    }

    Component.onCompleted: root.refreshFlights()

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refreshFlights()
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08131F" }
            GradientStop { position: 0.45; color: "#102A43" }
            GradientStop { position: 1.0; color: "#F4F7FB" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 4
                Label {
                    text: "Mapa Lotów"
                    font.pixelSize: 32
                    font.bold: true
                    color: "#F8FAFC"
                }
                Label {
                    text: "Pozycje samolotów liczone z czasu lotu i współrzędnych lotnisk"
                    font.pixelSize: 14
                    color: "#D0D7DE"
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                radius: 18
                color: "#FFFFFF"
                opacity: 0.94
                border.color: "#DDE6EE"
                border.width: 1
                implicitHeight: 84
                implicitWidth: 360

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Label { text: "W trakcie"; font.pixelSize: 11; color: "#6B7280" }
                        Label { text: String(root.currentFlightCount); font.pixelSize: 24; font.bold: true; color: "#0F172A" }
                    }

                    ColumnLayout {
                        spacing: 2
                        Label { text: "Nadchodzące"; font.pixelSize: 11; color: "#6B7280" }
                        Label { text: String(root.upcomingFlightCount); font.pixelSize: 24; font.bold: true; color: "#0F172A" }
                    }

                    ColumnLayout {
                        spacing: 2
                        Label { text: "Zakończone"; font.pixelSize: 11; color: "#6B7280" }
                        Label { text: String(root.finishedFlightCount); font.pixelSize: 24; font.bold: true; color: "#0F172A" }
                    }
                }
            }
        }

        Pane {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            Material.elevation: 0
            background: Rectangle {
                radius: 22
                color: "#07111D"
                border.color: "#19324A"
                border.width: 1
            }

            Canvas {
                id: mapCanvas
                anchors.fill: parent
                anchors.margins: 1
                antialiasing: true

                onPaint: {
                    var context = getContext("2d")
                    var w = width
                    var h = height

                    context.clearRect(0, 0, w, h)

                    var background = context.createLinearGradient(0, 0, 0, h)
                    background.addColorStop(0, "#0B1522")
                    background.addColorStop(1, "#15324B")
                    context.fillStyle = background
                    context.fillRect(0, 0, w, h)

                    context.save()
                    context.globalAlpha = 0.18
                    context.strokeStyle = "#9FB7C9"
                    context.lineWidth = 1
                    for (var lon = -180; lon <= 180; lon += 30) {
                        var x = root.project(0, lon, w, h).x
                        context.beginPath()
                        context.moveTo(x, 0)
                        context.lineTo(x, h)
                        context.stroke()
                    }
                    for (var lat = -60; lat <= 60; lat += 30) {
                        var y = root.project(lat, 0, w, h).y
                        context.beginPath()
                        context.moveTo(0, y)
                        context.lineTo(w, y)
                        context.stroke()
                    }
                    context.restore()

                    context.save()
                    context.globalAlpha = 0.55
                    context.strokeStyle = "#6EE7B7"
                    context.lineWidth = 2
                    context.setLineDash([8, 8])
                    context.strokeRect(24, 24, w - 48, h - 48)
                    context.restore()

                    context.font = "12px Segoe UI"
                    context.textBaseline = "middle"

                    if (!root.flights || root.flights.length === 0) {
                        context.fillStyle = "#DDE6EE"
                        context.textAlign = "center"
                        context.font = "18px Segoe UI"
                        context.fillText("Brak lotów do pokazania", w / 2, h / 2)
                        return
                    }

                    for (var i = 0; i < root.flights.length; ++i) {
                        var flight = root.flights[i]
                        var depLat = root.toNumber(flight.depLatitude)
                        var depLon = root.toNumber(flight.depLongitude)
                        var arrLat = root.toNumber(flight.arrLatitude)
                        var arrLon = root.toNumber(flight.arrLongitude)

                        if (!isFinite(depLat) || !isFinite(depLon) || !isFinite(arrLat) || !isFinite(arrLon)) {
                            continue
                        }

                        var timing = root.flightTiming(flight)
                        var startPoint = root.project(depLat, depLon, w, h)
                        var endPoint = root.project(arrLat, arrLon, w, h)
                        var currentPoint = {
                            x: startPoint.x + (endPoint.x - startPoint.x) * timing.progress,
                            y: startPoint.y + (endPoint.y - startPoint.y) * timing.progress
                        }

                        var routeColor = timing.active ? "#59C3FF" : (timing.finished ? "#9CA3AF" : "#FBBF24")
                        var planeColor = timing.active ? "#7DD3FC" : (timing.finished ? "#CBD5E1" : "#FDE68A")

                        context.save()
                        context.globalAlpha = timing.active ? 0.95 : 0.55
                        context.strokeStyle = routeColor
                        context.lineWidth = timing.active ? 3 : 2
                        context.beginPath()
                        context.moveTo(startPoint.x, startPoint.y)
                        context.lineTo(endPoint.x, endPoint.y)
                        context.stroke()
                        context.restore()

                        context.save()
                        context.fillStyle = "#22C55E"
                        context.beginPath()
                        context.arc(startPoint.x, startPoint.y, 5, 0, Math.PI * 2)
                        context.fill()
                        context.strokeStyle = "#E8FFF1"
                        context.lineWidth = 2
                        context.stroke()
                        context.restore()

                        context.save()
                        context.fillStyle = "#F97316"
                        context.beginPath()
                        context.arc(endPoint.x, endPoint.y, 5, 0, Math.PI * 2)
                        context.fill()
                        context.strokeStyle = "#FFF7ED"
                        context.lineWidth = 2
                        context.stroke()
                        context.restore()

                        context.save()
                        context.fillStyle = planeColor
                        context.strokeStyle = "#07111D"
                        context.lineWidth = 2
                        context.beginPath()
                        context.moveTo(currentPoint.x, currentPoint.y - 10)
                        context.lineTo(currentPoint.x + 8, currentPoint.y + 8)
                        context.lineTo(currentPoint.x, currentPoint.y + 4)
                        context.lineTo(currentPoint.x - 8, currentPoint.y + 8)
                        context.closePath()
                        context.fill()
                        context.stroke()
                        context.restore()

                        context.save()
                        context.fillStyle = "#F8FAFC"
                        context.strokeStyle = "rgba(7,17,29,0.65)"
                        context.lineWidth = 4
                        context.textAlign = "left"
                        var label = flight.planeName + " • " + flight.depIcao + " → " + flight.arrIcao
                        context.strokeText(label, currentPoint.x + 14, currentPoint.y - 2)
                        context.fillText(label, currentPoint.x + 14, currentPoint.y - 2)
                        context.restore()
                    }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 20
                radius: 16
                color: "#F8FAFC"
                opacity: 0.95
                border.color: "#D8E2EA"
                border.width: 1
                implicitWidth: 240
                implicitHeight: 120

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Label {
                        text: "Legenda"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#0F172A"
                    }

                    RowLayout {
                        spacing: 8
                        Rectangle { width: 12; height: 12; radius: 6; color: "#22C55E" }
                        Label { text: "Start trasy"; color: "#334155"; font.pixelSize: 12 }
                    }
                    RowLayout {
                        spacing: 8
                        Rectangle { width: 12; height: 12; radius: 6; color: "#F97316" }
                        Label { text: "Koniec trasy"; color: "#334155"; font.pixelSize: 12 }
                    }
                    RowLayout {
                        spacing: 8
                        Rectangle { width: 12; height: 12; radius: 6; color: "#59C3FF" }
                        Label { text: "Samolot w locie"; color: "#334155"; font.pixelSize: 12 }
                    }
                }
            }
        }
    }
}