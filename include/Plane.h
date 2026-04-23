#ifndef PLANE_H
#define PLANE_H

#include <QObject>
#include <QString>

class Plane : public QObject {
    Q_OBJECT

    // Definicja wlasciwosci dostepnych w QML i C++
    Q_PROPERTY(int id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString brand READ brand WRITE setBrand NOTIFY brandChanged)
    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(QString imagePath READ imagePath WRITE setImagePath NOTIFY imagePathChanged)
    Q_PROPERTY(int thrust READ thrust WRITE setThrust NOTIFY thrustChanged)
    Q_PROPERTY(double length READ length WRITE setLength NOTIFY lengthChanged)
    Q_PROPERTY(int numberOfEngines READ numberOfEngines WRITE setNumberOfEngines NOTIFY numberOfEnginesChanged)
    Q_PROPERTY(int passengers READ passengers WRITE setPassengers NOTIFY passengersChanged)
    Q_PROPERTY(double maxSpeed READ maxSpeed WRITE setMaxSpeed NOTIFY maxSpeedChanged)
    Q_PROPERTY(double maxAltitude READ maxAltitude WRITE setMaxAltitude NOTIFY maxAltitudeChanged)

public:
    explicit Plane(QObject *parent = nullptr);

    // Gettery
    int id() const { return m_id; }
    QString brand() const { return m_brand; }
    QString model() const { return m_model; }
    QString status() const { return m_status; }
    QString imagePath() const { return m_imagePath; }
    int thrust() const { return m_thrust; }
    double length() const { return m_length; }
    int numberOfEngines() const { return m_numberOfEngines; }
    int passengers() const { return m_passengers; }
    double maxSpeed() const { return m_maxSpeed; }
    double maxAltitude() const { return m_maxAltitude; }

    // Settery
    void setId(int id);
    void setBrand(const QString &brand);
    void setModel(const QString &model);
    void setStatus(const QString &status);
    void setImagePath(const QString &path);
    void setThrust(int thrust);
    void setLength(double length);
    void setNumberOfEngines(int numberOfEngines);
    void setPassengers(int passengers);
    void setMaxSpeed(double maxSpeed);
    void setMaxAltitude(double maxAltitude);

signals:
    // Sygnaly informujace UI o zmianie danych
    void idChanged();
    void brandChanged();
    void modelChanged();
    void statusChanged();
    void imagePathChanged();
    void thrustChanged();
    void lengthChanged();
    void numberOfEnginesChanged();
    void passengersChanged();
    void maxSpeedChanged();
    void maxAltitudeChanged();

private:
    int m_id;
    QString m_brand;
    QString m_model;
    QString m_status;
    QString m_imagePath; // URL do Supabase Storage
    int m_thrust;
    double m_length;
    int m_numberOfEngines;
    int m_passengers;
    double m_maxSpeed;
    double m_maxAltitude;
};

#endif // PLANE_H