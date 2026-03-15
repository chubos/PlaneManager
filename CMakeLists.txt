cmake_minimum_required(VERSION 3.16)

project(PlaneManager VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Automatyczna obsługa plików Qt
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Znajdź potrzebne pakiety
set(CMAKE_PREFIX_PATH "C:/Qt/6.10.2/mingw_64" CACHE PATH "Qt path")
find_package(Qt6 REQUIRED COMPONENTS Quick Widgets Sql Network)

qt_add_executable(PlaneManager
    src/main.cpp
)

qt_add_qml_module(PlaneManager
    URI PlaneManager
    VERSION 1.0
    QML_FILES
        qml/main.qml
)

target_link_libraries(PlaneManager PRIVATE 
    Qt6::Quick 
    Qt6::Widgets 
    Qt6::Sql 
    Qt6::Network
)