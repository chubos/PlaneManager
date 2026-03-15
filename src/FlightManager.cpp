#include "FlightManager.h"

FlightManager::FlightManager(QObject *parent) : QObject(parent) {}

bool FlightManager::addFlight(int planeId, int depAirportId, int arrAirportId, 
                              const QDateTime &startTime, const QDateTime &endTime) {
    QSqlQuery query;
    query.prepare("INSERT INTO flights (plane_id, departure_airport_id, arrival_airport_id, start_time, end_time) "
                  "VALUES (:pId, :depId, :arrId, :start, :end)");
    query.bindValue(":pId", planeId);
    query.bindValue(":depId", depAirportId);
    query.bindValue(":arrId", arrAirportId);
    query.bindValue(":start", startTime);
    query.bindValue(":end", endTime);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy dodawaniu lotu:" << query.lastError().text();
        return false;
    }
    qDebug() << "Pomyslnie zarezerwowano lot.";
    return true;
}

QVariantList FlightManager::getAllFlights() {
    QVariantList list;
    // Pobieramy ID, ale tez czytelne nazwy dzieki JOIN
    QString sql = "SELECT f.id, p.brand, p.model, "
                  "dep.icao_code as dep_icao, arr.icao_code as arr_icao, "
                  "f.start_time, f.end_time, "
                  "f.plane_id, f.departure_airport_id, f.arrival_airport_id "
                  "FROM flights f "
                  "JOIN planes p ON f.plane_id = p.id "
                  "JOIN airports dep ON f.departure_airport_id = dep.id "
                  "JOIN airports arr ON f.arrival_airport_id = arr.id "
                  "ORDER BY f.start_time DESC";

    QSqlQuery query(sql);
    while (query.next()) {
        QVariantMap map;
        map["id"] = query.value("id");
        map["planeName"] = query.value("brand").toString() + " " + query.value("model").toString();
        map["depIcao"] = query.value("dep_icao");
        map["arrIcao"] = query.value("arr_icao");
        map["startTime"] = query.value("start_time").toDateTime().toString("dd.MM.yyyy HH:mm");
        map["endTime"] = query.value("end_time").toDateTime().toString("dd.MM.yyyy HH:mm");
        
        // Te ID beda potrzebne przy edycji (zeby ustawic ComboBoxy)
        map["planeId"] = query.value("plane_id");
        map["depAirportId"] = query.value("departure_airport_id");
        map["arrAirportId"] = query.value("arrival_airport_id");
        
        list.append(map);
    }
    return list;
}

bool FlightManager::updateFlight(int id, int planeId, int depAirportId, int arrAirportId, 
                                 const QDateTime &startTime, const QDateTime &endTime) {
    QSqlQuery query;
    query.prepare("UPDATE flights SET plane_id = :pId, departure_airport_id = :depId, "
                  "arrival_airport_id = :arrId, start_time = :start, end_time = :end "
                  "WHERE id = :id");
    query.bindValue(":pId", planeId);
    query.bindValue(":depId", depAirportId);
    query.bindValue(":arrId", arrAirportId);
    query.bindValue(":start", startTime);
    query.bindValue(":end", endTime);
    query.bindValue(":id", id);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy edycji lotu:" << query.lastError().text();
        return false;
    }
    return true;
}

bool FlightManager::deleteFlight(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM flights WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy usuwaniu lotu:" << query.lastError().text();
        return false;
    }
    qDebug() << "Pomyslnie usunieto lot o ID:" << id;
    return true;
}