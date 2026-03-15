#include "Plane.h"

Plane::Plane(QObject *parent) : QObject(parent), m_id(0) {}

void Plane::setId(int id) {
    if (m_id != id) {
        m_id = id;
        emit idChanged();
    }
}

void Plane::setBrand(const QString &brand) {
    if (m_brand != brand) {
        m_brand = brand;
        emit brandChanged();
    }
}

void Plane::setModel(const QString &model) {
    if (m_model != model) {
        m_model = model;
        emit modelChanged();
    }
}

void Plane::setStatus(const QString &status) {
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
    }
}

void Plane::setImagePath(const QString &path) {
    if (m_imagePath != path) {
        m_imagePath = path;
        emit imagePathChanged();
    }
}