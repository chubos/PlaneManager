#include "OsmNetworkAccessManager.h"

#include <QByteArray>
#include <QDir>
#include <QNetworkDiskCache>
#include <QNetworkRequest>
#include <QStandardPaths>
#include <QUrl>

OsmNetworkAccessManager::OsmNetworkAccessManager(QObject *parent)
    : QNetworkAccessManager(parent) {}

QNetworkReply *OsmNetworkAccessManager::createRequest(Operation op, const QNetworkRequest &req, QIODevice *outgoingData) {
    QNetworkRequest request(req);

    const QString host = request.url().host().toLower();
    if (host == "tile.openstreetmap.org") {
        const QByteArray contact = qEnvironmentVariable("OSM_TILE_CONTACT").toUtf8();

        QByteArray userAgent = "PlaneManager/1.0 (Qt desktop map client";
        if (!contact.isEmpty()) {
            userAgent += "; contact=" + contact;
        }
        userAgent += ")";

        request.setRawHeader("User-Agent", userAgent);
        request.setRawHeader("Referer", "https://openstreetmap.org/");
    }

    return QNetworkAccessManager::createRequest(op, request, outgoingData);
}

QNetworkAccessManager *OsmNetworkAccessManagerFactory::create(QObject *parent) {
    auto *manager = new OsmNetworkAccessManager(parent);

    const QString cacheRoot = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    if (!cacheRoot.isEmpty()) {
        const QString cachePath = cacheRoot + "/osm-tile-cache";
        QDir().mkpath(cachePath);

        auto *cache = new QNetworkDiskCache(manager);
        cache->setCacheDirectory(cachePath);
        cache->setMaximumCacheSize(200ll * 1024ll * 1024ll); // 200 MB
        manager->setCache(cache);
    }

    return manager;
}
