#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>

class DatabaseManager : public QObject {
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    // Metoda dostepna z poziomu QML (dzieki Q_INVOKABLE)
    Q_INVOKABLE bool connectToSupabase();

    // Sprawdzenie czy polaczenie jest aktywne
    bool isConnected() const;

private:
    QSqlDatabase m_db;
};

#endif