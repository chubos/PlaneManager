#ifndef PLANEMANAGER_H
#define PLANEMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QNetworkAccessManager>

class PlaneManager : public QObject {
    Q_OBJECT
public:
    explicit PlaneManager(QObject *parent = nullptr);

    // Dodawanie nowego samolotu
    Q_INVOKABLE bool addPlane(const QString &brand, const QString &model, const QString &status,
                              int thrust, double length, int numberOfEngines, 
                              int passengers, double maxSpeed, double maxAltitude);

    // Pobieranie listy wszystkich samolotow (dla ListView w QML)
    Q_INVOKABLE QVariantList getAllPlanes();

    // Edycja istniejacego samolotu
    Q_INVOKABLE bool updatePlane(int id, const QString &brand, const QString &model, const QString &status,
                                 int thrust, double length, int numberOfEngines, 
                                 int passengers, double maxSpeed, double maxAltitude, const QString &imagePath = "");

    // Usuwanie samolotu
    Q_INVOKABLE bool deletePlane(int id);
    Q_INVOKABLE void uploadImage(int planeId, const QString &filePath);

signals:
    void imageUploadFinished(int planeId, bool success, const QString &msg);

private slots:
    void onUploadDone();

private:
    QNetworkAccessManager *m_net;
    QMap<QNetworkReply*, int> m_map;
};

#endif