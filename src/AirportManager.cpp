#include "AirportManager.h"

AirportManager::AirportManager(QObject *parent) : QObject(parent) {}

bool AirportManager::addAirport(const QString &icao, const QString &name, double lat, double lon) {
    QSqlQuery query;
    query.prepare("INSERT INTO airports (icao_code, name, latitude, longitude) "
                  "VALUES (:icao, :name, :lat, :lon)");
    query.bindValue(":icao", icao);
    query.bindValue(":name", name);
    query.bindValue(":lat", lat);
    query.bindValue(":lon", lon);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy dodawaniu lotniska:" << query.lastError().text();
        return false;
    }
    qDebug() << "Pomyslnie dodano lotnisko:" << icao;
    return true;
}

QVariantList AirportManager::getAllAirports() {
    QVariantList list;
    QSqlQuery query("SELECT id, icao_code, name, latitude, longitude FROM airports ORDER BY icao_code ASC");

    while (query.next()) {
        QVariantMap map;
        map["id"] = query.value("id");
        map["icaoCode"] = query.value("icao_code");
        map["name"] = query.value("name");
        map["latitude"] = query.value("latitude");
        map["longitude"] = query.value("longitude");
        list.append(map);
    }
    return list;
}

bool AirportManager::updateAirport(int id, const QString &icao, const QString &name, double lat, double lon) {
    QSqlQuery query;
    query.prepare("UPDATE airports SET icao_code = :icao, name = :name, "
                  "latitude = :lat, longitude = :lon WHERE id = :id");
    query.bindValue(":icao", icao);
    query.bindValue(":name", name);
    query.bindValue(":lat", lat);
    query.bindValue(":lon", lon);
    query.bindValue(":id", id);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy edycji lotniska:" << query.lastError().text();
        return false;
    }
    return true;
}

bool AirportManager::deleteAirport(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM airports WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy usuwaniu lotniska:" << query.lastError().text();
        return false;
    }
    return true;
}