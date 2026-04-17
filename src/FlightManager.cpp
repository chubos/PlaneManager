#include "FlightManager.h"

FlightManager::FlightManager(QObject *parent) : QObject(parent) {}

namespace {
QDateTime toDbUtc(const QDateTime &dateTime) {
    if (!dateTime.isValid()) {
        return dateTime;
    }
    return dateTime.toUTC();
}

QDateTime toLocalForDisplay(const QVariant &value) {
    QDateTime dateTime = value.toDateTime();
    if (!dateTime.isValid()) {
        return dateTime;
    }

    if (dateTime.timeSpec() == Qt::UTC || dateTime.timeSpec() == Qt::OffsetFromUTC) {
        return dateTime.toLocalTime();
    }

    return dateTime;
}

QDateTime toUtcForCompare(const QVariant &value) {
    QDateTime dateTime = value.toDateTime();
    if (!dateTime.isValid()) {
        return dateTime;
    }
    if (dateTime.timeSpec() == Qt::UTC || dateTime.timeSpec() == Qt::OffsetFromUTC) {
        return dateTime.toUTC();
    }
    return dateTime.toUTC();
}

bool isPlaneInService(int planeId) {
    QSqlQuery query;
    query.prepare("SELECT LOWER(COALESCE(status, '')) AS status FROM planes WHERE id = :planeId");
    query.bindValue(":planeId", planeId);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy sprawdzaniu statusu samolotu:" << query.lastError().text();
        return true;
    }

    if (!query.next()) {
        qDebug() << "Nie znaleziono samolotu o ID:" << planeId;
        return true;
    }

    return query.value("status").toString() == "w serwisie";
}

bool hasPlaneScheduleConflict(int planeId, const QDateTime &startUtc, const QDateTime &endUtc, int excludedFlightId = -1) {
    if (!startUtc.isValid() || !endUtc.isValid() || endUtc <= startUtc) {
        return true;
    }

    QSqlQuery query;
    if (excludedFlightId >= 0) {
        query.prepare("SELECT 1 FROM flights "
                      "WHERE plane_id = :planeId AND id <> :excludedId "
                      "AND start_time < :endUtc AND end_time > :startUtc "
                      "LIMIT 1");
        query.bindValue(":excludedId", excludedFlightId);
    } else {
        query.prepare("SELECT 1 FROM flights "
                      "WHERE plane_id = :planeId "
                      "AND start_time < :endUtc AND end_time > :startUtc "
                      "LIMIT 1");
    }

    query.bindValue(":planeId", planeId);
    query.bindValue(":startUtc", startUtc);
    query.bindValue(":endUtc", endUtc);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy sprawdzaniu kolizji lotu:" << query.lastError().text();
        return true;
    }

    return query.next();
}
}

bool FlightManager::addFlight(int planeId, int depAirportId, int arrAirportId, 
                              const QDateTime &startTime, const QDateTime &endTime) {
    const QDateTime startUtc = toDbUtc(startTime);
    const QDateTime endUtc = toDbUtc(endTime);

    if (isPlaneInService(planeId)) {
        qDebug() << "Nie mozna zarezerwowac lotu: samolot jest w serwisie.";
        return false;
    }

    if (hasPlaneScheduleConflict(planeId, startUtc, endUtc)) {
        qDebug() << "Nie mozna zarezerwowac lotu: samolot ma juz zajety termin.";
        return false;
    }

    QSqlQuery query;
    query.prepare("INSERT INTO flights (plane_id, departure_airport_id, arrival_airport_id, start_time, end_time) "
                  "VALUES (:pId, :depId, :arrId, :start, :end)");
    query.bindValue(":pId", planeId);
    query.bindValue(":depId", depAirportId);
    query.bindValue(":arrId", arrAirportId);
    query.bindValue(":start", startUtc);
    query.bindValue(":end", endUtc);

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
    const QDateTime nowUtc = QDateTime::currentDateTimeUtc();
    while (query.next()) {
        const QDateTime startUtc = toUtcForCompare(query.value("start_time"));
        const QDateTime endUtc = toUtcForCompare(query.value("end_time"));

        QString statusText = "Zaplanowany";
        QString statusColor = "#2E7D32";

        if (startUtc.isValid() && endUtc.isValid()) {
            if (nowUtc < startUtc) {
                statusText = "Zaplanowany";
                statusColor = "#2E7D32";
            } else if (nowUtc <= endUtc) {
                statusText = "W trakcie";
                statusColor = "#F9A825";
            } else {
                statusText = "Zakończony";
                statusColor = "#C62828";
            }
        }

        QVariantMap map;
        map["id"] = query.value("id");
        map["planeName"] = query.value("brand").toString() + " " + query.value("model").toString();
        map["depIcao"] = query.value("dep_icao");
        map["arrIcao"] = query.value("arr_icao");
        map["startTime"] = toLocalForDisplay(query.value("start_time")).toString("dd.MM.yyyy HH:mm");
        map["endTime"] = toLocalForDisplay(query.value("end_time")).toString("dd.MM.yyyy HH:mm");
        map["status"] = statusText;
        map["statusColor"] = statusColor;
        
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
    const QDateTime startUtc = toDbUtc(startTime);
    const QDateTime endUtc = toDbUtc(endTime);

    if (isPlaneInService(planeId)) {
        qDebug() << "Nie mozna zaktualizowac lotu: samolot jest w serwisie.";
        return false;
    }

    if (hasPlaneScheduleConflict(planeId, startUtc, endUtc, id)) {
        qDebug() << "Nie mozna zaktualizowac lotu: samolot ma juz zajety termin.";
        return false;
    }

    QSqlQuery query;
    query.prepare("UPDATE flights SET plane_id = :pId, departure_airport_id = :depId, "
                  "arrival_airport_id = :arrId, start_time = :start, end_time = :end "
                  "WHERE id = :id");
    query.bindValue(":pId", planeId);
    query.bindValue(":depId", depAirportId);
    query.bindValue(":arrId", arrAirportId);
    query.bindValue(":start", startUtc);
    query.bindValue(":end", endUtc);
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