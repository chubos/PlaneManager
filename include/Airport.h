#ifndef AIRPORT_H
#define AIRPORT_H

#include <QObject>
#include <QString>

class Airport : public QObject {
    Q_OBJECT

    // Właściwości dla QML: kod ICAO, nazwa oraz współrzędne GPS
    Q_PROPERTY(int id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString icaoCode READ icaoCode WRITE setIcaoCode NOTIFY icaoCodeChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(double latitude READ latitude WRITE setLatitude NOTIFY latitudeChanged)
    Q_PROPERTY(double longitude READ longitude WRITE setLongitude NOTIFY longitudeChanged)

public:
    explicit Airport(QObject *parent = nullptr);

    // Gettery
    int id() const { return m_id; }
    QString icaoCode() const { return m_icaoCode; }
    QString name() const { return m_name; }
    double latitude() const { return m_latitude; }
    double longitude() const { return m_longitude; }

    // Settery
    void setId(int id);
    void setIcaoCode(const QString &code);
    void setName(const QString &name);
    void setLatitude(double lat);
    void setLongitude(double lon);

signals:
    void idChanged();
    void icaoCodeChanged();
    void nameChanged();
    void latitudeChanged();
    void longitudeChanged();

private:
    int m_id;
    QString m_icaoCode;
    QString m_name;
    double m_latitude;
    double m_longitude;
};

#endif // AIRPORT_H