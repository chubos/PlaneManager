#ifndef FLIGHT_H
#define FLIGHT_H

#include <QObject>
#include <QDateTime>

class Flight : public QObject {
    Q_OBJECT

    Q_PROPERTY(int id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(int planeId READ planeId WRITE setPlaneId NOTIFY planeIdChanged)
    Q_PROPERTY(int departureAirportId READ departureAirportId WRITE setDepartureAirportId NOTIFY departureAirportIdChanged)
    Q_PROPERTY(int arrivalAirportId READ arrivalAirportId WRITE setArrivalAirportId NOTIFY arrivalAirportIdChanged)
    Q_PROPERTY(QDateTime startTime READ startTime WRITE setStartTime NOTIFY startTimeChanged)
    Q_PROPERTY(QDateTime endTime READ endTime WRITE setEndTime NOTIFY endTimeChanged)

public:
    explicit Flight(QObject *parent = nullptr);

    // Gettery
    int id() const { return m_id; }
    int planeId() const { return m_planeId; }
    int departureAirportId() const { return m_departureAirportId; }
    int arrivalAirportId() const { return m_arrivalAirportId; }
    QDateTime startTime() const { return m_startTime; }
    QDateTime endTime() const { return m_endTime; }

    // Settery
    void setId(int id);
    void setPlaneId(int planeId);
    void setDepartureAirportId(int id);
    void setArrivalAirportId(int id);
    void setStartTime(const QDateTime &time);
    void setEndTime(const QDateTime &time);

    // Metoda pomocnicza dla logiki statusu
    Q_INVOKABLE bool isCurrentlyFlying() const;

signals:
    void idChanged();
    void planeIdChanged();
    void departureAirportIdChanged();
    void arrivalAirportIdChanged();
    void startTimeChanged();
    void endTimeChanged();

private:
    int m_id;
    int m_planeId;
    int m_departureAirportId;
    int m_arrivalAirportId;
    QDateTime m_startTime;
    QDateTime m_endTime;
};

#endif // FLIGHT_H