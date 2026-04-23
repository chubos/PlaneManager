#include "Plane.h"

Plane::Plane(QObject *parent) : QObject(parent), m_id(0), m_thrust(0), m_length(0), 
                                  m_numberOfEngines(1), m_passengers(0), m_maxSpeed(0), 
                                  m_maxAltitude(0) {}

void Plane::setId(int id) {
    if (m_id != id) {
        m_id = id;
        emit idChanged();
    }
}

void Plane::setBrand(const QString &brand) {
    if (m_brand != brand) {
        m_brand = brand;
        emit brandChanged();
    }
}

void Plane::setModel(const QString &model) {
    if (m_model != model) {
        m_model = model;
        emit modelChanged();
    }
}

void Plane::setStatus(const QString &status) {
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
    }
}

void Plane::setImagePath(const QString &path) {
    if (m_imagePath != path) {
        m_imagePath = path;
        emit imagePathChanged();
    }
}

void Plane::setThrust(int thrust) {
    if (m_thrust != thrust) {
        m_thrust = thrust;
        emit thrustChanged();
    }
}

void Plane::setLength(double length) {
    if (m_length != length) {
        m_length = length;
        emit lengthChanged();
    }
}

void Plane::setNumberOfEngines(int numberOfEngines) {
    if (m_numberOfEngines != numberOfEngines) {
        m_numberOfEngines = numberOfEngines;
        emit numberOfEnginesChanged();
    }
}

void Plane::setPassengers(int passengers) {
    if (m_passengers != passengers) {
        m_passengers = passengers;
        emit passengersChanged();
    }
}

void Plane::setMaxSpeed(double maxSpeed) {
    if (m_maxSpeed != maxSpeed) {
        m_maxSpeed = maxSpeed;
        emit maxSpeedChanged();
    }
}

void Plane::setMaxAltitude(double maxAltitude) {
    if (m_maxAltitude != maxAltitude) {
        m_maxAltitude = maxAltitude;
        emit maxAltitudeChanged();
    }
}