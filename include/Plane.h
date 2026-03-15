#ifndef PLANE_H
#define PLANE_H

#include <QObject>
#include <QString>

class Plane : public QObject {
    Q_OBJECT

    // Definicja właściwości dostępnych w QML i C++
    Q_PROPERTY(int id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString brand READ brand WRITE setBrand NOTIFY brandChanged)
    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(QString imagePath READ imagePath WRITE setImagePath NOTIFY imagePathChanged)

public:
    explicit Plane(QObject *parent = nullptr);

    // Gettery
    int id() const { return m_id; }
    QString brand() const { return m_brand; }
    QString model() const { return m_model; }
    QString status() const { return m_status; }
    QString imagePath() const { return m_imagePath; }

    // Settery
    void setId(int id);
    void setBrand(const QString &brand);
    void setModel(const QString &model);
    void setStatus(const QString &status);
    void setImagePath(const QString &path);

signals:
    // Sygnały informujące UI o zmianie danych
    void idChanged();
    void brandChanged();
    void modelChanged();
    void statusChanged();
    void imagePathChanged();

private:
    int m_id;
    QString m_brand;
    QString m_model;
    QString m_status;
    QString m_imagePath; // URL do Supabase Storage
};

#endif // PLANE_H