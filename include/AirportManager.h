#ifndef AIRPORTMANAGER_H
#define AIRPORTMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

class AirportManager : public QObject {
    Q_OBJECT
public:
    explicit AirportManager(QObject *parent = nullptr);

    // Dodawanie nowego lotniska (np. z formularza)
    Q_INVOKABLE bool addAirport(const QString &icao, const QString &name, double lat, double lon);

    // Pobieranie wszystkich lotnisk (do wyswietlenia na liscie lub mapie)
    Q_INVOKABLE QVariantList getAllAirports();

    // Edycja danych lotniska
    Q_INVOKABLE bool updateAirport(int id, const QString &icao, const QString &name, double lat, double lon);

    // Usuwanie lotniska
    Q_INVOKABLE bool deleteAirport(int id);
};

#endif // AIRPORTMANAGER_H