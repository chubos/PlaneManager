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
    
    qDebug() << "=== Upload Image START ===";
    qDebug() << "PlaneID:" << planeId << "File:" << filePath;
    qDebug() << "SUPABASE_URL:" << supabaseUrl;
    qDebug() << "SUPABASE_SERVICE_ROLE_KEY:" << (supabaseKey.isEmpty() ? "NOT SET" : "SET");
    
    // Usuń wszystkie możliwe stare formaty zanim upload nowego
    QStringList extensions = {"jpg", "jpeg", "png", "bmp", "gif"};
    for (const auto& ext : extensions) {
        auto deleteUrl = supabaseUrl + "/storage/v1/object/planes/plane_" + QString::number(planeId) + "/image." + ext;
        QNetworkRequest delReq;
        delReq.setUrl(QUrl(deleteUrl));
        delReq.setRawHeader("Authorization", ("Bearer " + supabaseKey).toUtf8());
        auto delReply = m_net->deleteResource(delReq);
        connect(delReply, &QNetworkReply::finished, delReply, &QNetworkReply::deleteLater);
        qDebug() << "DELETE old image." + ext;
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
    qDebug() << "PUT request sent, waiting for response...";
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