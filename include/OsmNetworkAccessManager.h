#ifndef OSMNETWORKACCESSMANAGER_H
#define OSMNETWORKACCESSMANAGER_H

#include <QNetworkAccessManager>
#include <QQmlNetworkAccessManagerFactory>

class QIODevice;
class QNetworkReply;
class QNetworkRequest;

class OsmNetworkAccessManager final : public QNetworkAccessManager {
public:
    explicit OsmNetworkAccessManager(QObject *parent = nullptr);

protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &req, QIODevice *outgoingData) override;
};

class OsmNetworkAccessManagerFactory final : public QQmlNetworkAccessManagerFactory {
public:
    QNetworkAccessManager *create(QObject *parent) override;
};

#endif // OSMNETWORKACCESSMANAGER_H
