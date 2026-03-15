#include "DatabaseManager.h"
#include <QProcessEnvironment>

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent) {
    // Sprawdzamy, czy sterownik PostgreSQL jest dostepny
    if (!QSqlDatabase::isDriverAvailable("QPSQL")) {
        qCritical() << "BLAD: Sterownik QPSQL (PostgreSQL) nie jest dostepny w Twoim systemie Qt!";
    }
    m_db = QSqlDatabase::addDatabase("QPSQL");
}

DatabaseManager::~DatabaseManager() {
    if (m_db.isOpen()) {
        m_db.close();
    }
}

bool DatabaseManager::connectToSupabase() {
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    
    m_db.setHostName(env.value("DB_HOST"));
    m_db.setDatabaseName(env.value("DB_NAME"));
    m_db.setUserName(env.value("DB_USER"));
    m_db.setPassword(env.value("DB_PASS"));
    m_db.setPort(env.value("DB_PORT").toInt());

    // Dodaj te linie, aby uniknac problemow z wygasaniem sesji na poolerze
    m_db.setConnectOptions("keepalives=1;connect_timeout=10");

    if (!m_db.open()) {
        qDebug() << "Blad polaczenia z Supabase:" << m_db.lastError().text();
        return false;
    }

    qDebug() << "Pomyslnie polaczono z baza danych Supabase!";
    return true;
}

bool DatabaseManager::isConnected() const {
    return m_db.isOpen();
}