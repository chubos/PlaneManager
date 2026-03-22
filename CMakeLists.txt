cmake_minimum_required(VERSION 3.16)

project(PlaneManager VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Automatyczna obsluga plikow Qt
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Znajdz potrzebne pakiety
set(CMAKE_PREFIX_PATH "C:/Qt/6.10.2/mingw_64" CACHE PATH "Qt path")
find_package(Qt6 REQUIRED COMPONENTS Quick Widgets Sql Network QuickControls2)
set(PostgreSQL_ROOT "C:/Program Files/PostgreSQL/18" CACHE PATH "PostgreSQL path")
find_package(PostgreSQL REQUIRED)

qt_standard_project_setup(REQUIRES 6.10)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

qt_add_executable(PlaneManager
    src/main.cpp
    src/Flight.cpp
    src/Plane.cpp
    src/Airport.cpp
    src/DatabaseManager.cpp
    src/PlaneManager.cpp
    src/AirportManager.cpp
    src/FlightManager.cpp
    include/Flight.h
    include/Plane.h
    include/Airport.h
    include/DatabaseManager.h
    include/PlaneManager.h
    include/AirportManager.h
    include/FlightManager.h
)

target_include_directories(PlaneManager PRIVATE include/)

qt_add_qml_module(PlaneManager
    URI PlaneManager
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/PlaneList.qml
        qml/AirportList.qml
        qml/FlightList.qml
)

target_link_libraries(PlaneManager PRIVATE 
    Qt6::Quick 
    Qt6::Widgets 
    Qt6::Sql 
    Qt6::Network
    Qt6::QuickControls2
    PostgreSQL::PostgreSQL
)