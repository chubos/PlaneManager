pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtLocation
import QtPositioning

Item {
    id: root
    objectName: "mapView"

    // qmllint disable unqualified
    readonly property var service: flightService
    // qmllint enable unqualified

    property var flights: []
    property var allFlights: []
    property real nowUtcMs: Date.now()

    property int currentFlightCount: 0
    property int upcomingFlightCount: 0
    property int finishedFlightCount: 0

    property bool autoFitDone: false

Plugin {
    id: osmPlugin
    name: "osm"

    PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
    PluginParameter { name: "osm.mapping.custom.host"; value: "https://tile.openstreetmap.org/" }
    PluginParameter { name: "osm.useragent"; value: "MyFlightTrackerApp/1.0" }
    PluginParameter { name: "osm.mapping.highdpi_tiles"; value: true }
}

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function interpolateCoordinate(depLat, depLon, arrLat, arrLon, progress) {
        var lat = depLat + (arrLat - depLat) * progress
        var lon = depLon + (arrLon - depLon) * progress
        
        // Obsługa antypodów: jeśli różnica > 180°, przejdź drugą drogą
        var lonDiff = arrLon - depLon
        if (lonDiff > 180) {
            lon = depLon + (arrLon - 360 - depLon) * progress
        } else if (lonDiff < -180) {
            lon = depLon + (arrLon + 360 - depLon) * progress
        }
        
        // Normalizuj do [-180, 180]
        while (lon > 180) lon -= 360
        while (lon < -180) lon += 360
        
        return QtPositioning.coordinate(lat, lon)
    }

    function toNumber(value) {
        if (value === undefined || value === null) {
            return NaN
        }

        if (typeof value === "string") {
            var normalized = value.trim().replace(",", ".")
            return Number(normalized)
        }

        return Number(value)
    }

    function isCoordValid(lat, lon) {
        var latitude = toNumber(lat)
        var longitude = toNumber(lon)
        return isFinite(latitude) && isFinite(longitude)
               && latitude >= -90 && latitude <= 90
               && longitude >= -180 && longitude <= 180
    }

    function toCoordinate(lat, lon) {
        return QtPositioning.coordinate(toNumber(lat), toNumber(lon))
    }

    function preferredMapType(types) {
        if (!types || types.length === 0) {
            return null
        }

        // Zawsze zwracaj CustomMap (OSM), to jest konsistent
        for (var i = 0; i < types.length; ++i) {
            if (types[i].style === MapType.CustomMap) {
                return types[i]
            }
        }

        // Fallback na pierwszy dostępny, ale preferuj CustomMap
        return types[0]
    }

    function flightTiming(flight, currentMs) {
        var startMs = toNumber(flight.startTimeUtcMs)
        var endMs = toNumber(flight.endTimeUtcMs)
        var totalMs = endMs - startMs

        if (!isFinite(startMs) || !isFinite(endMs) || totalMs <= 0) {
            return { progress: 0, active: false, finished: false, upcoming: true }
        }

        if (currentMs <= startMs) {
            return { progress: 0, active: false, finished: false, upcoming: true }
        }

        if (currentMs >= endMs) {
            return { progress: 1, active: false, finished: true, upcoming: false }
        }

        return {
            progress: clamp((currentMs - startMs) / totalMs, 0, 1),
            active: true,
            finished: false,
            upcoming: false
        }
    }

    function updateCounters() {
        currentFlightCount = 0
        upcomingFlightCount = 0
        finishedFlightCount = 0

        for (var i = 0; i < flights.length; ++i) {
            var timing = flightTiming(flights[i], nowUtcMs)
            if (timing.active) {
                currentFlightCount += 1
            } else if (timing.finished) {
                finishedFlightCount += 1
            } else {
                upcomingFlightCount += 1
            }
        }

        // Count finished flights from all flights (including those not on map)
        for (var j = 0; j < allFlights.length; ++j) {
            var timingAll = flightTiming(allFlights[j], nowUtcMs)
            if (timingAll.finished) {
                finishedFlightCount += 1
            }
        }
    }

    function valueOr(obj, keyA, keyB, fallbackValue) {
        if (obj && obj[keyA] !== undefined && obj[keyA] !== null) {
            return obj[keyA]
        }
        if (obj && obj[keyB] !== undefined && obj[keyB] !== null) {
            return obj[keyB]
        }
        return fallbackValue
    }

    function normalizeFlight(raw) {
        var depLat = toNumber(valueOr(raw, "depLatitude", "dep_latitude", NaN))
        var depLon = toNumber(valueOr(raw, "depLongitude", "dep_longitude", NaN))
        var arrLat = toNumber(valueOr(raw, "arrLatitude", "arr_latitude", NaN))
        var arrLon = toNumber(valueOr(raw, "arrLongitude", "arr_longitude", NaN))

        return {
            id: valueOr(raw, "id", "flightId", -1),
            planeName: valueOr(raw, "planeName", "plane_name", "Samolot"),
            depIcao: valueOr(raw, "depIcao", "dep_icao", "DEP"),
            arrIcao: valueOr(raw, "arrIcao", "arr_icao", "ARR"),
            depLatitude: depLat,
            depLongitude: depLon,
            arrLatitude: arrLat,
            arrLongitude: arrLon,
            startTimeUtcMs: toNumber(valueOr(raw, "startTimeUtcMs", "start_time_utc_ms", NaN)),
            endTimeUtcMs: toNumber(valueOr(raw, "endTimeUtcMs", "end_time_utc_ms", NaN)),
            status: valueOr(raw, "status", "flightStatus", "")
        }
    }

    function refreshFlights() {
        var rawFlights = service.getAllFlights()

        if (!rawFlights) {
            flights = []
            allFlights = []
            updateCounters()
            return
        }

        var newFlights = []
        var now = Date.now()
        
        // Store all flights for counting
        var allFlightsData = []
        for (var i = 0; i < rawFlights.length; ++i) {
            var normalized = normalizeFlight(rawFlights[i])
            allFlightsData.push(normalized)
        }

        // Filter only active flights for map display
        for (var k = 0; k < allFlightsData.length; ++k) {
            var flight = allFlightsData[k]
            if (flight.startTimeUtcMs <= now && now <= flight.endTimeUtcMs) {
                newFlights.push(flight)
            }
        }

        allFlights = allFlightsData
        flights = newFlights
        updateCounters()
        fitMapToFlightsIfNeeded()
    }

    function fitMapToFlightsIfNeeded() {
        if (autoFitDone || flights.length === 0 || mapView.width <= 0 || mapView.height <= 0) {
            return
        }

        var minLat = 90
        var maxLat = -90
        var minLon = 180
        var maxLon = -180
        var found = false

        for (var i = 0; i < flights.length; ++i) {
            var f = flights[i]
            var points = [
                [f.depLatitude, f.depLongitude],
                [f.arrLatitude, f.arrLongitude]
            ]

            for (var j = 0; j < points.length; ++j) {
                var lat = toNumber(points[j][0])
                var lon = toNumber(points[j][1])
                if (!isFinite(lat) || !isFinite(lon)) {
                    continue
                }

                minLat = Math.min(minLat, lat)
                maxLat = Math.max(maxLat, lat)
                minLon = Math.min(minLon, lon)
                maxLon = Math.max(maxLon, lon)
                found = true
            }
        }

        if (!found) {
            return
        }

        var centerLat = (minLat + maxLat) / 2
        var centerLon = (minLon + maxLon) / 2
        var span = Math.max(maxLat - minLat, maxLon - minLon)

        mapView.center = QtPositioning.coordinate(centerLat, centerLon)
        mapView.zoomLevel = clamp(
            span < 1 ? 9 : (span < 5 ? 6 : (span < 20 ? 4 : (span < 60 ? 3 : 2))),
            mapView.minimumZoomLevel,
            mapView.maximumZoomLevel
        )
        autoFitDone = true
    }

    function resetMapView() {
        autoFitDone = false
        mapView.center = QtPositioning.coordinate(20, 0)
        mapView.zoomLevel = 2.2
        fitMapToFlightsIfNeeded()
    }

    Component.onCompleted: refreshFlights()

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            root.nowUtcMs = Date.now()
            root.updateCounters()
        }
    }

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
                    text: "Pozycja samolotu liczona z czasu lotu"
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
                color: "#07111D"
                border.color: "#19324A"
                border.width: 1
            }

            Map {
                id: mapView
                anchors.fill: parent
                anchors.margins: 1
                plugin: osmPlugin
                center: QtPositioning.coordinate(20, 0)
                zoomLevel: 2.2
                minimumZoomLevel: 1
                maximumZoomLevel: 18
                copyrightsVisible: false
                activeMapType: root.preferredMapType(supportedMapTypes)

                MapItemView {
                    model: root.flights

                    delegate: MapPolyline {
                        required property var model
                        readonly property var timing: root.flightTiming(model, root.nowUtcMs)
                        readonly property bool coordsValid: root.isCoordValid(model.depLatitude, model.depLongitude)
                                                           && root.isCoordValid(model.arrLatitude, model.arrLongitude)
                        autoFadeIn: false
                        visible: coordsValid
                        z: 100
                        path: [
                            root.toCoordinate(model.depLatitude, model.depLongitude),
                            root.toCoordinate(model.arrLatitude, model.arrLongitude)
                        ]
                        line.width: timing.active ? 4 : 2
                        line.color: timing.active ? "#4FB6FF" : (timing.finished ? "#7A8796" : "#F7B84B")
                        opacity: timing.active ? 0.95 : 0.55
                    }
                }

                MapItemView {
                    model: root.flights

                    delegate: MapQuickItem {
                        id: depMarker
                        required property var model
                        autoFadeIn: false
                        visible: root.isCoordValid(model.depLatitude, model.depLongitude)
                        z: 200
                        coordinate: root.toCoordinate(model.depLatitude, model.depLongitude)
                        anchorPoint.x: 8
                        anchorPoint.y: 8
                        zoomLevel: 0
                        sourceItem: Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: "#22C55E"
                            border.color: "#EAF7EF"
                            border.width: 2

                            Label {
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 3
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: String(depMarker.model.depIcao)
                                color: "#DCFCE7"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }

                MapItemView {
                    model: root.flights

                    delegate: MapQuickItem {
                        id: arrMarker
                        required property var model
                        autoFadeIn: false
                        visible: root.isCoordValid(model.arrLatitude, model.arrLongitude)
                        z: 200
                        coordinate: root.toCoordinate(model.arrLatitude, model.arrLongitude)
                        anchorPoint.x: 8
                        anchorPoint.y: 8
                        zoomLevel: 0
                        sourceItem: Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: "#F97316"
                            border.color: "#FFF4E8"
                            border.width: 2

                            Label {
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 3
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: String(arrMarker.model.arrIcao)
                                color: "#FFEDD5"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }

                MapItemView {
                    model: root.flights

                    delegate: MapQuickItem {
                        id: planeMarker
                        required property var model
                        readonly property var timing: root.flightTiming(model, root.nowUtcMs)
                        readonly property var depCoord: root.toCoordinate(model.depLatitude, model.depLongitude)
                        readonly property var arrCoord: root.toCoordinate(model.arrLatitude, model.arrLongitude)
                        readonly property real progress: timing.progress

                        autoFadeIn: false
                        visible: root.isCoordValid(model.depLatitude, model.depLongitude)
                                 && root.isCoordValid(model.arrLatitude, model.arrLongitude)
                        z: 300
                        coordinate: root.interpolateCoordinate(
                            model.depLatitude, model.depLongitude,
                            model.arrLatitude, model.arrLongitude,
                            progress
                        )
                        anchorPoint.x: 16
                        anchorPoint.y: 16
                        zoomLevel: 0
                        sourceItem: Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: planeMarker.timing.active ? "#0F172A" : (planeMarker.timing.finished ? "#1F2937" : "#1E293B")
                            border.color: planeMarker.timing.active ? "#7DD3FC" : (planeMarker.timing.finished ? "#A3A3A3" : "#FACC15")
                            border.width: 2
                            opacity: planeMarker.timing.active ? 1.0 : 0.9

                            Label {
                                anchors.centerIn: parent
                                text: "✈"
                                color: "#E0F2FE"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.bottom
                                anchors.topMargin: 4
                                radius: 8
                                color: "#0B1522"
                                border.color: "#25435F"
                                border.width: 1
                                implicitWidth: flightLabel.implicitWidth + 12
                                implicitHeight: flightLabel.implicitHeight + 6

                                Label {
                                    id: flightLabel
                                    anchors.centerIn: parent
                                    text: String(planeMarker.model.planeName) + "  " + String(planeMarker.model.depIcao) + "->" + String(planeMarker.model.arrIcao)
                                    color: "#E2E8F0"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        var nextZoom = root.clamp(mapView.zoomLevel + (event.angleDelta.y > 0 ? 0.5 : -0.5), mapView.minimumZoomLevel, mapView.maximumZoomLevel)
                        if (nextZoom === mapView.zoomLevel) {
                            return
                        }
                        mapView.zoomLevel = nextZoom
                        event.accepted = true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.OpenHandCursor

                    property real lastMouseX: 0
                    property real lastMouseY: 0

                    onPressed: function(mouse) {
                        lastMouseX = mouse.x
                        lastMouseY = mouse.y
                        cursorShape = Qt.ClosedHandCursor
                    }

                    onReleased: cursorShape = Qt.OpenHandCursor

                    onPositionChanged: function(mouse) {
                        if (!(mouse.buttons & Qt.LeftButton)) {
                            return
                        }

                        var dx = mouse.x - lastMouseX
                        var dy = mouse.y - lastMouseY
                        mapView.pan(-dx, -dy)

                        lastMouseX = mouse.x
                        lastMouseY = mouse.y
                    }

                    onDoubleClicked: function(mouse) {
                        var anchor = Qt.point(mouse.x, mouse.y)
                        var coord = mapView.toCoordinate(anchor)
                        mapView.zoomLevel = root.clamp(mapView.zoomLevel + 1, mapView.minimumZoomLevel, mapView.maximumZoomLevel)
                        mapView.alignCoordinateToPoint(coord, anchor)
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                radius: 6
                color: "#111827"
                opacity: 0.75
                implicitHeight: 22
                implicitWidth: attributionLabel.implicitWidth + 14

                Label {
                    id: attributionLabel
                    anchors.centerIn: parent
                    text: "Map tiles: © OpenStreetMap contributors"
                    color: "#E5E7EB"
                    font.pixelSize: 10
                }
            }

        }
    }
}
