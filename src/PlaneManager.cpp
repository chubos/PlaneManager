#include "PlaneManager.h"

PlaneManager::PlaneManager(QObject *parent) : QObject(parent) {}

bool PlaneManager::addPlane(const QString &brand, const QString &model, const QString &status) {
    QSqlQuery query;
    query.prepare("INSERT INTO planes (brand, model, status) VALUES (:brand, :model, :status)");
    query.bindValue(":brand", brand);
    query.bindValue(":model", model);
    query.bindValue(":status", status);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy dodawaniu samolotu:" << query.lastError().text();
        return false;
    }

    qDebug() << "Pomyslnie dodano samolot:" << brand << model;
    return true;
}

QVariantList PlaneManager::getAllPlanes() {
    QVariantList list;
    QSqlQuery query("SELECT id, brand, model, status FROM planes ORDER BY id DESC");

    while (query.next()) {
        QVariantMap map;
        map["id"] = query.value("id");
        map["brand"] = query.value("brand");
        map["model"] = query.value("model");
        map["status"] = query.value("status");
        list.append(map);
    }
    return list;
}

bool PlaneManager::updatePlane(int id, const QString &brand, const QString &model, const QString &status) {
    QSqlQuery query;
    query.prepare("UPDATE planes SET brand = :brand, model = :model, status = :status WHERE id = :id");
    query.bindValue(":brand", brand);
    query.bindValue(":model", model);
    query.bindValue(":status", status);
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