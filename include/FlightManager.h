#ifndef FLIGHTMANAGER_H
#define FLIGHTMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QDateTime>

class FlightManager : public QObject {
    Q_OBJECT
public:
    explicit FlightManager(QObject *parent = nullptr);

    // Dodawanie nowego lotu
    Q_INVOKABLE bool addFlight(int planeId, int depAirportId, int arrAirportId, 
                               const QDateTime &startTime, const QDateTime &endTime);

    // Pobieranie wszystkich lotow z polaczeniem tabel (JOIN)
    Q_INVOKABLE QVariantList getAllFlights();

    // Edycja istniejacego lotu
    Q_INVOKABLE bool updateFlight(int id, int planeId, int depAirportId, int arrAirportId, 
                                  const QDateTime &startTime, const QDateTime &endTime);

    // Usuwanie lotu
    Q_INVOKABLE bool deleteFlight(int id);
};

#endif // FLIGHTMANAGER_H