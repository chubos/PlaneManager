#include "PlaneManager.h"
#include <QProcessEnvironment>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QFile>
#include <QFileInfo>
#include <QUrl>
#include <QDateTime>

PlaneManager::PlaneManager(QObject *parent) : QObject(parent) {
    m_net = new QNetworkAccessManager(this);
}

bool PlaneManager::addPlane(const QString &brand, const QString &model, const QString &status,
                              int thrust, double length, int numberOfEngines, 
                              int passengers, double maxSpeed, double maxAltitude) {
    QSqlQuery query;
    query.prepare("INSERT INTO planes (brand, model, status, thrust, length, number_of_engines, passengers, max_speed, max_altitude, image_path) "
                  "VALUES (:brand, :model, :status, :thrust, :length, :numberOfEngines, :passengers, :maxSpeed, :maxAltitude, '')");
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
        "COALESCE(p.image_path, '') as image_path, "
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
        map["imagePath"] = query.value("image_path");
        list.append(map);
    }
    return list;
}

bool PlaneManager::updatePlane(int id, const QString &brand, const QString &model, const QString &status,
                                 int thrust, double length, int numberOfEngines, 
                                 int passengers, double maxSpeed, double maxAltitude, const QString &imagePath) {
    QSqlQuery query;
    query.prepare("UPDATE planes SET brand = :brand, model = :model, status = :status, thrust = :thrust, length = :length, "
                  "number_of_engines = :numberOfEngines, passengers = :passengers, max_speed = :maxSpeed, max_altitude = :maxAltitude, "
                  "image_path = :imagePath WHERE id = :id");
    query.bindValue(":brand", brand);
    query.bindValue(":model", model);
    query.bindValue(":status", status);
    query.bindValue(":thrust", thrust);
    query.bindValue(":length", length);
    query.bindValue(":numberOfEngines", numberOfEngines);
    query.bindValue(":passengers", passengers);
    query.bindValue(":maxSpeed", maxSpeed);
    query.bindValue(":maxAltitude", maxAltitude);
    query.bindValue(":imagePath", imagePath.isEmpty() ? QVariant() : imagePath);
    query.bindValue(":id", id);

    if (!query.exec()) {
        qDebug() << "Blad SQL przy aktualizacji samolotu:" << query.lastError().text();
        return false;
    }
    qDebug() << "Pomyslnie zaktualizowano samolot ID:" << id;
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
    qDebug() << "Pomyslnie usunieto samolot ID:" << id;
    return true;
}

void PlaneManager::uploadImage(int planeId, const QString &filePath) {
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly)) {
        qDebug() << "Upload Image ERROR - nie mozna otworzyc pliku:" << filePath;
        emit imageUploadFinished(planeId, false, "Nie można otworzyć pliku");
        return;
    }
    
    QByteArray fileData = f.readAll();
    qDebug() << "File size:" << fileData.size() << "bytes";
    
    auto env = QProcessEnvironment::systemEnvironment();
    auto supabaseUrl = env.value("SUPABASE_URL");
    auto supabaseKey = env.value("SUPABASE_SERVICE_ROLE_KEY");
    
    
    // Usuń wszystkie możliwe stare formaty zanim upload nowego
    QStringList extensions = {"jpg", "jpeg", "png", "bmp", "gif"};
    for (const auto& ext : extensions) {
        auto deleteUrl = supabaseUrl + "/storage/v1/object/planes/plane_" + QString::number(planeId) + "/image." + ext;
        QNetworkRequest delReq;
        delReq.setUrl(QUrl(deleteUrl));
        delReq.setRawHeader("Authorization", ("Bearer " + supabaseKey).toUtf8());
        auto delReply = m_net->deleteResource(delReq);
        connect(delReply, &QNetworkReply::finished, delReply, &QNetworkReply::deleteLater);
    }
    
    // Upload nowego pliku
    auto url = supabaseUrl + "/storage/v1/object/planes/plane_" + 
              QString::number(planeId) + "/image." + QFileInfo(filePath).suffix();
    
    qDebug() << "Upload URL:" << url;
    
    QNetworkRequest req;
    req.setUrl(QUrl(url));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/octet-stream");
    req.setRawHeader("Authorization", ("Bearer " + supabaseKey).toUtf8());
    req.setTransferTimeout(60000);
    
    qDebug() << "Sending PUT with" << fileData.size() << "bytes";
    auto reply = m_net->put(req, fileData);
    connect(reply, &QNetworkReply::finished, this, &PlaneManager::onUploadDone);
    m_map[reply] = planeId;
    f.close();
    qDebug() << "PUT request sent.";
}

void PlaneManager::onUploadDone() {
    qDebug() << "===== onUploadDone CALLED =====" << QDateTime::currentDateTime().toString();
    
    auto reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        qDebug() << "ERROR: reply is nullptr!";
        return;
    }
    
    qDebug() << "Reply obtained. m_map.size():" << m_map.size();
    int id = m_map.take(reply);
    qDebug() << "PlaneID from map:" << id << "Reply error code:" << reply->error();
    qDebug() << "Error string:" << reply->errorString();
    
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "HTTP Error detected";
        QByteArray errorBody = reply->readAll();
        qDebug() << "Error response body:" << errorBody;
        emit imageUploadFinished(id, false, reply->errorString());
        reply->deleteLater();
        return;
    }
    
    qDebug() << "No HTTP error, proceeding to update DB";
    auto env = QProcessEnvironment::systemEnvironment();
    // Public URL dla dostępu do pliku
    auto publicUrl = env.value("SUPABASE_URL") + "/storage/v1/object/public/planes/plane_" + 
                    QString::number(id) + "/image." + reply->url().toString().split(".").last();
    
    QSqlQuery q;
    q.prepare("UPDATE planes SET image_path = :p WHERE id = :id");
    q.bindValue(":p", publicUrl);
    q.bindValue(":id", id);
    bool ok = q.exec();
    qDebug() << "DB Update:" << (ok ? "OK" : "FAILED");
    if (!ok) qDebug() << "SQL Error:" << q.lastError().text();
    qDebug() << "Image URL saved:" << publicUrl;
    emit imageUploadFinished(id, ok, ok ? "OK" : q.lastError().text());
    reply->deleteLater();
    qDebug() << "===== onUploadDone FINISHED =====";
}

QVariantMap PlaneManager::getStatistics() {
    QVariantMap stats;
    
    QSqlQuery query;
    query.prepare(
        "SELECT "
        "COUNT(*) as total_planes, "
        "SUM(CASE WHEN "
        "    EXISTS (SELECT 1 FROM flights f WHERE f.plane_id = p.id AND f.start_time <= CURRENT_TIMESTAMP AND f.end_time >= CURRENT_TIMESTAMP) "
        "    THEN 1 ELSE 0 END) as in_flight, "
        "SUM(CASE WHEN LOWER(COALESCE(p.status, '')) = 'w serwisie' THEN 1 ELSE 0 END) as in_service, "
        "SUM(CASE WHEN "
        "    NOT EXISTS (SELECT 1 FROM flights f WHERE f.plane_id = p.id AND f.start_time <= CURRENT_TIMESTAMP AND f.end_time >= CURRENT_TIMESTAMP) "
        "    AND LOWER(COALESCE(p.status, '')) != 'w serwisie' "
        "    THEN 1 ELSE 0 END) as available, "
        "AVG(p.length) as avg_length, "
        "AVG(p.passengers) as avg_passengers, "
        "MAX(p.length) as max_length, "
        "MIN(p.length) as min_length, "
        "MAX(p.passengers) as max_passengers, "
        "MIN(p.passengers) as min_passengers "
        "FROM planes p"
    );
    
    if (query.exec() && query.next()) {
        stats["totalPlanes"] = query.value("total_planes").toInt();
        stats["availablePlanes"] = query.value("available").isNull() ? 0 : query.value("available").toInt();
        stats["inServicePlanes"] = query.value("in_service").isNull() ? 0 : query.value("in_service").toInt();
        stats["inFlightPlanes"] = query.value("in_flight").isNull() ? 0 : query.value("in_flight").toInt();
        stats["avgLength"] = query.value("avg_length").isNull() ? 0.0 : query.value("avg_length").toDouble();
        stats["avgPassengers"] = query.value("avg_passengers").isNull() ? 0.0 : query.value("avg_passengers").toDouble();
        stats["maxLength"] = query.value("max_length").isNull() ? 0.0 : query.value("max_length").toDouble();
        stats["minLength"] = query.value("min_length").isNull() ? 0.0 : query.value("min_length").toDouble();
        stats["maxPassengers"] = query.value("max_passengers").isNull() ? 0 : query.value("max_passengers").toInt();
        stats["minPassengers"] = query.value("min_passengers").isNull() ? 0 : query.value("min_passengers").toInt();
    } else {
        qDebug() << "Error fetching statistics:" << query.lastError().text();
        // Ustaw domyślne wartości
        stats["totalPlanes"] = 0;
        stats["availablePlanes"] = 0;
        stats["inServicePlanes"] = 0;
        stats["inFlightPlanes"] = 0;
        stats["avgLength"] = 0.0;
        stats["avgPassengers"] = 0.0;
        stats["maxLength"] = 0.0;
        stats["minLength"] = 0.0;
        stats["maxPassengers"] = 0;
        stats["minPassengers"] = 0;
    }
    
    return stats;
}

QVariantMap PlaneManager::getExtremeAircrafts() {
    QVariantMap extremes;

    QSqlQuery query;
    query.prepare(R"SQL(
        SELECT
            (SELECT brand FROM planes WHERE length IS NOT NULL ORDER BY length DESC, id ASC LIMIT 1)      AS maxLengthBrand,
            (SELECT model FROM planes WHERE length IS NOT NULL ORDER BY length DESC, id ASC LIMIT 1)      AS maxLengthModel,
            (SELECT length FROM planes WHERE length IS NOT NULL ORDER BY length DESC, id ASC LIMIT 1)     AS maxLengthValue,

            (SELECT brand FROM planes WHERE length IS NOT NULL ORDER BY length ASC, id ASC LIMIT 1)       AS minLengthBrand,
            (SELECT model FROM planes WHERE length IS NOT NULL ORDER BY length ASC, id ASC LIMIT 1)       AS minLengthModel,
            (SELECT length FROM planes WHERE length IS NOT NULL ORDER BY length ASC, id ASC LIMIT 1)      AS minLengthValue,

            (SELECT brand FROM planes WHERE passengers IS NOT NULL ORDER BY passengers DESC, id ASC LIMIT 1)   AS maxPassengersBrand,
            (SELECT model FROM planes WHERE passengers IS NOT NULL ORDER BY passengers DESC, id ASC LIMIT 1)   AS maxPassengersModel,
            (SELECT passengers FROM planes WHERE passengers IS NOT NULL ORDER BY passengers DESC, id ASC LIMIT 1) AS maxPassengersValue,

            (SELECT brand FROM planes WHERE passengers IS NOT NULL ORDER BY passengers ASC, id ASC LIMIT 1)    AS minPassengersBrand,
            (SELECT model FROM planes WHERE passengers IS NOT NULL ORDER BY passengers ASC, id ASC LIMIT 1)    AS minPassengersModel,
            (SELECT passengers FROM planes WHERE passengers IS NOT NULL ORDER BY passengers ASC, id ASC LIMIT 1) AS minPassengersValue
        WHERE EXISTS (SELECT 1 FROM planes)
    )SQL");

    if (!query.exec()) {
        qDebug() << "Blad SQL przy pobieraniu ekstremow:" << query.lastError().text();
        return extremes;
    }
    if (!query.next()) {
        return extremes;
    }

    extremes["maxLengthBrand"] = query.value("maxLengthBrand");
    extremes["maxLengthModel"] = query.value("maxLengthModel");
    extremes["maxLengthValue"] = query.value("maxLengthValue");

    extremes["minLengthBrand"] = query.value("minLengthBrand");
    extremes["minLengthModel"] = query.value("minLengthModel");
    extremes["minLengthValue"] = query.value("minLengthValue");

    extremes["maxPassengersBrand"] = query.value("maxPassengersBrand");
    extremes["maxPassengersModel"] = query.value("maxPassengersModel");
    extremes["maxPassengersValue"] = query.value("maxPassengersValue");

    extremes["minPassengersBrand"] = query.value("minPassengersBrand");
    extremes["minPassengersModel"] = query.value("minPassengersModel");
    extremes["minPassengersValue"] = query.value("minPassengersValue");
    
    return extremes;
}