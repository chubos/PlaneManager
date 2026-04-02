#include "AirportManager.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QtMath>
#include <QRegularExpression>
#include <QUrl>

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

QVariantMap AirportManager::parseGoogleMapsUrl(const QString &urlText) const {
    QVariantMap result;
    result["ok"] = false;

    const QString trimmedUrl = urlText.trimmed();
    if (trimmedUrl.isEmpty()) {
        result["error"] = "Wklej link Google Maps.";
        return result;
    }

    const QUrl url = QUrl::fromUserInput(trimmedUrl);
    if (!url.isValid()) {
        result["error"] = "Nieprawidlowy adres URL.";
        return result;
    }

    const QString decodedUrl = QUrl::fromPercentEncoding(url.toString().toUtf8());

    QString name;
    const QRegularExpression placeRegex("/place/([^/@?]+)");
    const QRegularExpressionMatch placeMatch = placeRegex.match(decodedUrl);
    if (placeMatch.hasMatch()) {
        name = placeMatch.captured(1).replace('+', ' ').trimmed();
    }

    bool latOk = false;
    bool lonOk = false;
    double latitude = 0.0;
    double longitude = 0.0;

    const QRegularExpression atRegex("/@(-?\\d+(?:\\.\\d+)?),(-?\\d+(?:\\.\\d+)?)");
    const QRegularExpressionMatch atMatch = atRegex.match(decodedUrl);
    if (atMatch.hasMatch()) {
        latitude = atMatch.captured(1).toDouble(&latOk);
        longitude = atMatch.captured(2).toDouble(&lonOk);
    }

    if (!(latOk && lonOk)) {
        const QRegularExpression coordsRegex("!3d(-?\\d+(?:\\.\\d+)?)!4d(-?\\d+(?:\\.\\d+)?)");
        const QRegularExpressionMatch coordsMatch = coordsRegex.match(decodedUrl);
        if (coordsMatch.hasMatch()) {
            latitude = coordsMatch.captured(1).toDouble(&latOk);
            longitude = coordsMatch.captured(2).toDouble(&lonOk);
        }
    }

    if (!(latOk && lonOk)) {
        result["error"] = "Nie znaleziono wspolrzednych w linku.";
        return result;
    }

    result["ok"] = true;
    result["name"] = name;
    result["latitude"] = latitude;
    result["longitude"] = longitude;

    const QVariantMap nearest = findNearestAirport(latitude, longitude);
    if (nearest.value("ok").toBool()) {
        result["icaoSuggested"] = nearest.value("icao");
        result["nameSuggested"] = nearest.value("name");
        result["distanceKm"] = nearest.value("distanceKm");
    }

    return result;
}

QVariantList AirportManager::searchReferenceAirportsByName(const QString &query, int limit) const {
    QVariantList results;
    if (!ensureReferenceAirportsLoaded()) {
        return results;
    }

    const QString needle = query.trimmed();
    if (needle.isEmpty()) {
        return results;
    }

    const int cappedLimit = qBound(1, limit, 20);
    for (const ReferenceAirport &airport : m_referenceAirports) {
        if (!airport.name.contains(needle, Qt::CaseInsensitive)) {
            continue;
        }

        QVariantMap item;
        item["icao"] = airport.icao;
        item["name"] = airport.name;
        item["latitude"] = airport.lat;
        item["longitude"] = airport.lon;
        results.append(item);

        if (results.size() >= cappedLimit) {
            break;
        }
    }

    return results;
}

bool AirportManager::ensureReferenceAirportsLoaded() const {
    if (m_referenceLoaded) {
        return !m_referenceAirports.isEmpty();
    }

    const QStringList candidatePaths = {
        ":/qt/qml/PlaneManager/assets/airports.json",
        ":/assets/airports.json",
        "assets/airports.json"
    };

    QByteArray jsonBytes;
    for (const QString &path : candidatePaths) {
        QFile file(path);
        if (file.open(QIODevice::ReadOnly)) {
            jsonBytes = file.readAll();
            file.close();
            break;
        }
    }

    m_referenceLoaded = true;
    if (jsonBytes.isEmpty()) {
        qDebug() << "Nie znaleziono airports.json do mapowania ICAO.";
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(jsonBytes, &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        qDebug() << "Niepoprawny format airports.json:" << parseError.errorString();
        return false;
    }

    const QJsonObject root = doc.object();
    m_referenceAirports.reserve(root.size());

    for (auto it = root.begin(); it != root.end(); ++it) {
        if (!it.value().isObject()) {
            continue;
        }

        const QJsonObject airportObj = it.value().toObject();
        const QString icao = airportObj.value("icao").toString().trimmed().toUpper();
        if (icao.isEmpty()) {
            continue;
        }

        bool latOk = false;
        bool lonOk = false;
        const double lat = airportObj.value("lat").toVariant().toDouble(&latOk);
        const double lon = airportObj.value("lon").toVariant().toDouble(&lonOk);
        if (!(latOk && lonOk)) {
            continue;
        }

        const QString name = airportObj.value("name").toString().trimmed();
        m_referenceAirports.append({icao, name, lat, lon});
    }

    return !m_referenceAirports.isEmpty();
}

QVariantMap AirportManager::findNearestAirport(double latitude, double longitude) const {
    QVariantMap result;
    result["ok"] = false;

    if (!ensureReferenceAirportsLoaded()) {
        return result;
    }

    int bestIndex = -1;
    double bestDistanceKm = std::numeric_limits<double>::max();

    for (int i = 0; i < m_referenceAirports.size(); ++i) {
        const ReferenceAirport &airport = m_referenceAirports.at(i);
        const double distanceKm = haversineKm(latitude, longitude, airport.lat, airport.lon);
        if (distanceKm < bestDistanceKm) {
            bestDistanceKm = distanceKm;
            bestIndex = i;
        }
    }

    if (bestIndex < 0) {
        return result;
    }

    const ReferenceAirport &best = m_referenceAirports.at(bestIndex);
    result["ok"] = true;
    result["icao"] = best.icao;
    result["name"] = best.name;
    result["distanceKm"] = bestDistanceKm;
    return result;
}

double AirportManager::haversineKm(double lat1, double lon1, double lat2, double lon2) {
    constexpr double earthRadiusKm = 6371.0;
    const double dLat = qDegreesToRadians(lat2 - lat1);
    const double dLon = qDegreesToRadians(lon2 - lon1);

    const double a = qSin(dLat / 2.0) * qSin(dLat / 2.0)
        + qCos(qDegreesToRadians(lat1)) * qCos(qDegreesToRadians(lat2))
        * qSin(dLon / 2.0) * qSin(dLon / 2.0);
    const double c = 2.0 * qAtan2(qSqrt(a), qSqrt(1.0 - a));
    return earthRadiusKm * c;
}