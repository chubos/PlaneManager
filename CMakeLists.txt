cmake_minimum_required(VERSION 3.16)

project(PlaneManager VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Automatyczna obsluga plikow Qt
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Znajdz potrzebne pakiety
set(CMAKE_PREFIX_PATH "C:/Qt/6.10.3/mingw_64" CACHE PATH "Qt path" FORCE)
find_package(Qt6 REQUIRED COMPONENTS Quick Widgets Sql Network QuickControls2 Positioning Location)
set(PostgreSQL_ROOT "C:/Program Files/PostgreSQL/18" CACHE PATH "PostgreSQL path")
find_package(PostgreSQL REQUIRED)

qt_standard_project_setup(REQUIRES 6.10)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

qt_add_executable(PlaneManager
    src/main.cpp
    src/DatabaseManager.cpp
    src/PlaneManager.cpp
    src/AirportManager.cpp
    src/FlightManager.cpp
    src/OsmNetworkAccessManager.cpp
    include/DatabaseManager.h
    include/PlaneManager.h
    include/AirportManager.h
    include/FlightManager.h
    include/OsmNetworkAccessManager.h
)

target_include_directories(PlaneManager PRIVATE include/)

qt_add_qml_module(PlaneManager
    URI PlaneManager
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/PlaneList.qml
        qml/PlaneDetail.qml
        qml/PlaneEditDialog.qml
        qml/AirportList.qml
        qml/FlightList.qml
        qml/MapView.qml
        qml/Statistics.qml
    RESOURCES
        assets/airports.json
        assets/airbus.png
        assets/boeing.png
        assets/embraer.png
        assets/bombardier.png
        assets/atr.png
        assets/cessna.png
        assets/gulfstream.png
        assets/dassault.png
        assets/antonov.png
        assets/sukhoi.png
        assets/icon.png
)

target_link_libraries(PlaneManager PRIVATE 
    Qt6::Quick 
    Qt6::Widgets 
    Qt6::Sql 
    Qt6::Network
    Qt6::QuickControls2
    Qt6::Positioning
    Qt6::Location
    PostgreSQL::PostgreSQL
)

if(WIN32 AND MINGW)
    # MinGW's windres is sensitive to space-containing include paths when CMake
    # compiles .rc as a language source. Use a minimal custom windres call.
    find_program(WINDRES_EXECUTABLE windres REQUIRED)
    set(APP_ICON_RC "${CMAKE_CURRENT_SOURCE_DIR}/PlaneManager.rc")
    set(APP_ICON_ICO "${CMAKE_CURRENT_SOURCE_DIR}/assets/icon.ico")
    set(APP_ICON_OBJ "${CMAKE_CURRENT_BINARY_DIR}/PlaneManagerIcon.obj")

    add_custom_command(
        OUTPUT "${APP_ICON_OBJ}"
        COMMAND "${WINDRES_EXECUTABLE}" -i "${APP_ICON_RC}" -o "${APP_ICON_OBJ}" -O coff
        DEPENDS "${APP_ICON_RC}" "${APP_ICON_ICO}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        VERBATIM
    )

    target_sources(PlaneManager PRIVATE "${APP_ICON_OBJ}")
elseif(WIN32)
    enable_language(RC)
    set_source_files_properties(PlaneManager.rc PROPERTIES LANGUAGE RC)
    target_sources(PlaneManager PRIVATE PlaneManager.rc)
endif()