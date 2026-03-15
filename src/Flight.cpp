#include "Flight.h"

Flight::Flight(QObject *parent) 
    : QObject(parent), m_id(0), m_planeId(0), 
      m_departureAirportId(0), m_arrivalAirportId(0) {}

void Flight::setId(int id) {
    if (m_id != id) { m_id = id; emit idChanged(); }
}

void Flight::setPlaneId(int planeId) {
    if (m_planeId != planeId) { m_planeId = planeId; emit planeIdChanged(); }
}

void Flight::setDepartureAirportId(int id) {
    if (m_departureAirportId != id) { m_departureAirportId = id; emit departureAirportIdChanged(); }
}

void Flight::setArrivalAirportId(int id) {
    if (m_arrivalAirportId != id) { m_arrivalAirportId = id; emit arrivalAirportIdChanged(); }
}

void Flight::setStartTime(const QDateTime &time) {
    if (m_startTime != time) { m_startTime = time; emit startTimeChanged(); }
}

void Flight::setEndTime(const QDateTime &time) {
    if (m_endTime != time) { m_endTime = time; emit endTimeChanged(); }
}

bool Flight::isCurrentlyFlying() const {
    QDateTime now = QDateTime::currentDateTime();
    return (now >= m_startTime && now <= m_endTime);
}