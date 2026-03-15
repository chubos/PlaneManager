#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Tutaj w przyszłości wstrzykniemy obiekt bazy danych:
    // engine.rootContext()->setContextProperty("dbManager", &yourDbManager);

    const QUrl url(u"qrc:/PlaneManager/qml/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}