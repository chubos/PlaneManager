#include "Airport.h"

Airport::Airport(QObject *parent) 
    : QObject(parent), m_id(0), m_latitude(0.0), m_longitude(0.0) {}

void Airport::setId(int id) {
    if (m_id != id) {
        m_id = id;
        emit idChanged();
    }
}

void Airport::setIcaoCode(const QString &code) {
    if (m_icaoCode != code) {
        m_icaoCode = code;
        emit icaoCodeChanged();
    }
}

void Airport::setName(const QString &name) {
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Airport::setLatitude(double lat) {
    if (qAbs(m_latitude - lat) > 0.000001) { // Porównanie dla typów zmiennoprzecinkowych
        m_latitude = lat;
        emit latitudeChanged();
    }
}

void Airport::setLongitude(double lon) {
    if (qAbs(m_longitude - lon) > 0.000001) {
        m_longitude = lon;
        emit longitudeChanged();
    }
}