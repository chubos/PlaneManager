#ifndef AIRPORTMANAGER_H
#define AIRPORTMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>
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

    // Parsowanie nazwy i wspolrzednych z linku Google Maps.
    Q_INVOKABLE QVariantMap parseGoogleMapsUrl(const QString &urlText) const;

    // Wyszukiwanie lotnisk referencyjnych po nazwie (podpowiedzi na zywo).
    Q_INVOKABLE QVariantList searchReferenceAirportsByName(const QString &query, int limit = 8) const;

private:
    struct ReferenceAirport {
        QString icao;
        QString name;
        double lat;
        double lon;
    };

    bool ensureReferenceAirportsLoaded() const;
    QVariantMap findNearestAirport(double latitude, double longitude) const;
    static double haversineKm(double lat1, double lon1, double lat2, double lon2);

    mutable QVector<ReferenceAirport> m_referenceAirports;
    mutable bool m_referenceLoaded = false;
};

#endif // AIRPORTMANAGER_H