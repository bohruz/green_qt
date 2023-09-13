#ifndef GREEN_ASSET_H
#define GREEN_ASSET_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QString>

class Asset : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network NOTIFY networkChanged);
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString icon READ icon NOTIFY iconChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)
    Q_PROPERTY(bool amp READ isAmp NOTIFY isAmpChanged)
    Q_PROPERTY(int weight READ weight NOTIFY weightChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Asset is instanced by AssetManager")
public:
    explicit Asset(const QString& id, QObject* parent);

    Network* network() const { return m_network; }
    void setNetwork(Network* network);

    QString id() const { return m_id; }
    QStandardItem* item() const { return m_item; }

    QString name() const { return m_name; }
    void setName(const QString& name);

    bool isLBTC() const;

    bool hasIcon() const { return !m_icon.isEmpty(); }
    QString icon() const { return m_icon; }
    void setIcon(const QString& icon);

    bool isAmp() const { return m_is_amp; }
    void setIsAmp(bool is_amp);
    int weight() const { return m_weight; }
    void setWeight(int weight);

    bool hasData() const { return !m_data.isEmpty(); }
    QJsonObject data() const { return m_data; }
    void setData(const QJsonObject& data);

    Q_INVOKABLE qint64 parseAmount(const QString& amount) const;
    Q_INVOKABLE QString formatAmount(qint64 amount, bool include_ticker, const QString& unit = {}) const;

public slots:
    void openInExplorer() const;

signals:
    void networkChanged();
    void nameChanged();
    void iconChanged();
    void dataChanged();
    void isAmpChanged();
    void weightChanged();

private:
    Network* m_network{nullptr};
    QString const m_id;
    QStandardItem* const m_item;
    QString m_name;
    QString m_icon;
    QJsonObject m_data;
    bool m_is_amp{false};
    int m_weight{0};
};

class AssetManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit AssetManager();;
    virtual ~AssetManager();
    static AssetManager* instance();

    AssetManager* create(QQmlEngine*, QJSEngine*);

    QStandardItemModel* model() const { return m_model; }

    Asset* assetWithId(const QString& id);

private:
    QMap<QString, Asset*> m_assets;
    QStandardItemModel* const m_model;
};

class AssetsModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int minWeight READ minWeight WRITE setMinWeight NOTIFY minWeightChanged)
    QML_ELEMENT
public:
    AssetsModel(QObject* parent = nullptr);
    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);
    int minWeight() const { return m_min_weight; }
    void setMinWeight(int min_weight);
signals:
    void filterChanged();
    void minWeightChanged();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
private:
    QString m_filter;
    int m_min_weight{0};
};

#endif // GREEN_ASSET_H
