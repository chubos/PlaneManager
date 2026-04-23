#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlNetworkAccessManagerFactory>
#include <QStringBuilder>
#include "DatabaseManager.h"
#include "PlaneManager.h"
#include "AirportManager.h"
#include "FlightManager.h"
#include <QFile>
#include <QTextStream>
#include <QQuickStyle>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>
#include <QNetworkRequest>
#include <QStandardPaths>
#include <QDir>

using namespace Qt::StringLiterals;

namespace {
class OsmNetworkAccessManager final : public QNetworkAccessManager {
public:
    explicit OsmNetworkAccessManager(QObject *parent = nullptr)
        : QNetworkAccessManager(parent) {}

protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &req, QIODevice *outgoingData) override {
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
};

class OsmNetworkAccessManagerFactory final : public QQmlNetworkAccessManagerFactory {
public:
    QNetworkAccessManager *create(QObject *parent) override {
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
};
}

void loadDotEnv(const QString &path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith("#")) continue;

        QStringList parts = line.split("=");
        if (parts.size() >= 2) {
            QString key = parts[0].trimmed();
            QString value = parts[1].trimmed();
            // Ustawia zmienna srodowiskowa dla biezacego procesu
            qputenv(key.toLocal8Bit(), value.toLocal8Bit());
        }
    }
}

int main(int argc, char *argv[]) {
    QQuickStyle::setStyle("Material");
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    engine.setNetworkAccessManagerFactory(new OsmNetworkAccessManagerFactory());

    loadDotEnv(QCoreApplication::applicationDirPath() + "/../.env");

    DatabaseManager dbManager;
    dbManager.connectToSupabase(); // Test polaczenia z baza danych
    engine.rootContext()->setContextProperty("myDb", &dbManager);
    
    // Udostepniamy obiekt dla QML
    PlaneManager planeManager;
    engine.rootContext()->setContextProperty("planeService", &planeManager);

    AirportManager airportManager;
    engine.rootContext()->setContextProperty("airportService", &airportManager);

    FlightManager flightManager;
    engine.rootContext()->setContextProperty("flightService", &flightManager);

    const QUrl url(u"qrc:/qt/qml/PlaneManager/qml/main.qml"_s);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}