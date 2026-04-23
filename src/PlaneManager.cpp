#include "PlaneManager.h"

PlaneManager::PlaneManager(QObject *parent) : QObject(parent) {}

bool PlaneManager::addPlane(const QString &brand, const QString &model, const QString &status,
                              int thrust, double length, int numberOfEngines, 
                              int passengers, double maxSpeed, double maxAltitude) {
    QSqlQuery query;
    query.prepare("INSERT INTO planes (brand, model, status, thrust, length, number_of_engines, passengers, max_speed, max_altitude) "
                  "VALUES (:brand, :model, :status, :thrust, :length, :numberOfEngines, :passengers, :maxSpeed, :maxAltitude)");
    query.bindValue(":brand", brand);
    query.bindValue(":model", model);
    query.bindValue(":status", status);
    query.bindValue(":thrust", thrust);
    query.bindValue(":length", length);
    query.bindValue(":numberOfEngines", numberOfEngines);
    query.bindValue(":passengers", passengers);
    query.bindValue(":maxSpeed", maxSpeed);
    query.bindValue(":maxAltitude", maxAltitude);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy dodawaniu samolotu:" << query.lastError().text();
        return false;
    }

    qDebug() << "Pomyslnie dodano samolot:" << brand << model;
    return true;
}

QVariantList PlaneManager::getAllPlanes() {
    QVariantList list;
    QSqlQuery query(
        "SELECT p.id, p.brand, p.model, p.thrust, p.length, p.number_of_engines, p.passengers, p.max_speed, p.max_altitude, "
        "CASE "
        "    WHEN EXISTS ("
        "        SELECT 1 FROM flights f "
        "        WHERE f.plane_id = p.id "
        "          AND f.start_time <= CURRENT_TIMESTAMP "
        "          AND f.end_time >= CURRENT_TIMESTAMP"
        "    ) THEN 'W locie' "
        "    WHEN LOWER(COALESCE(p.status, '')) = 'w locie' THEN 'Dostepny' "
        "    ELSE p.status "
        "END AS status "
        "FROM planes p "
        "ORDER BY p.id DESC"
    );

    while (query.next()) {
        QVariantMap map;
        map["id"] = query.value("id");
        map["brand"] = query.value("brand");
        map["model"] = query.value("model");
        map["status"] = query.value("status");
        map["thrust"] = query.value("thrust");
        map["length"] = query.value("length");
        map["numberOfEngines"] = query.value("number_of_engines");
        map["passengers"] = query.value("passengers");
        map["maxSpeed"] = query.value("max_speed");
        map["maxAltitude"] = query.value("max_altitude");
        list.append(map);
    }
    return list;
}

bool PlaneManager::updatePlane(int id, const QString &brand, const QString &model, const QString &status,
                                 int thrust, double length, int numberOfEngines, 
                                 int passengers, double maxSpeed, double maxAltitude) {
    QSqlQuery query;
    query.prepare("UPDATE planes SET brand = :brand, model = :model, status = :status, thrust = :thrust, length = :length, "
                  "number_of_engines = :numberOfEngines, passengers = :passengers, max_speed = :maxSpeed, max_altitude = :maxAltitude "
                  "WHERE id = :id");
    query.bindValue(":brand", brand);
    query.bindValue(":model", model);
    query.bindValue(":status", status);
    query.bindValue(":thrust", thrust);
    query.bindValue(":length", length);
    query.bindValue(":numberOfEngines", numberOfEngines);
    query.bindValue(":passengers", passengers);
    query.bindValue(":maxSpeed", maxSpeed);
    query.bindValue(":maxAltitude", maxAltitude);
    query.bindValue(":id", id);

    if (!query.exec()) {
        qDebug() << "Blad SQL podczas edycji samolotu:" << query.lastError().text();
        return false;
    }

    if (query.numRowsAffected() == 0) {
        qDebug() << "Nie znaleziono samolotu o ID:" << id;
        return false;
    }

    qDebug() << "Pomyslnie zaktualizowano samolot o ID:" << id;
    return true;
}

bool PlaneManager::deletePlane(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM planes WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy usuwaniu samolotu:" << query.lastError().text();
        return false;
    }

    qDebug() << "Pomyslnie usunieto samolot o ID:" << id;
    return true;
}