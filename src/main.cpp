#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStringBuilder>
#include "DatabaseManager.h"
#include "PlaneManager.h"
using namespace Qt::StringLiterals;
#include <QFile>
#include <QTextStream>

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
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    loadDotEnv(QCoreApplication::applicationDirPath() + "/../.env");

    DatabaseManager dbManager;
    dbManager.connectToSupabase(); // Test polaczenia z baza danych
    engine.rootContext()->setContextProperty("myDb", &dbManager);

    PlaneManager planeManager;
    // Udostepniamy obiekt dla QML
    engine.rootContext()->setContextProperty("planeService", &planeManager);

    const QUrl url(u"qrc:/qt/qml/PlaneManager/qml/main.qml"_s);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}