#include "analytics.h"
#include "asset.h"
#include "network.h"
#include "networkmanager.h"

#include <QDesktopServices>
#include <QLocale>
#include <QtMath>
#include <QUrl>

Asset::Asset(const QString& id, QObject* parent)
    : QObject(parent)
    , m_id(id)
    , m_item(new QStandardItem)
    , m_name(id)
{
    m_item->setData(QVariant::fromValue(this));
}

void Asset::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
}

void Asset::setIcon(const QString& icon)
{
    if (m_icon == icon) return;
    m_icon = icon;
    emit iconChanged();
}

void Asset::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
}

void Asset::setIsAmp(bool is_amp)
{
    if (m_is_amp == is_amp) return;
    m_is_amp = is_amp;
    emit isAmpChanged();
}

void Asset::setWeight(int weight)
{
    if (m_weight == weight) return;
    m_weight = weight;
    emit weightChanged();
    m_item->setData(m_weight, Qt::UserRole + 2);
}

void Asset::setData(const QJsonObject &data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();

    auto name = m_data.value("name").toString();
    if (name != "btc") setName(name.isEmpty() ? m_id : name);
//    if (name == "btc") return "Liquid Bitcoin";
//    return name;
}

qint64 Asset::parseAmount(const QString& amount) const
{
//    TODO parsing should be done from the account since the account holds the network
//    if (isLBTC()) {
//        return m_context->wallet()->amountToSats(amount);
//    }

    QString sanitized_amount = amount;
    sanitized_amount.replace(',', '.');
    auto precision = m_data.value("precision").toInt(0);
    bool ok;
    double result = sanitized_amount.toDouble(&ok);
    if (!ok) return 0;
    result *= qPow(10, precision);
    return result;
}

QString Asset::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
//    TODO format should be done from the account since the account holds the network
//    if (isLBTC()) {
//        return m_context->wallet()->formatAmount(amount, include_ticker, unit);
//    }

    auto precision = m_data.value("precision").toInt(0);
    auto str = QLocale::system().toString(static_cast<double>(amount) / qPow(10, precision), 'f', precision);

    if (include_ticker) {
        auto ticker = m_data.value("ticker").toString();
        if (!ticker.isEmpty()) str += " " + ticker;
    }

    return str;
}

void Asset::openInExplorer() const
{
    QDesktopServices::openUrl({ "https://blockstream.info/liquid/asset/" + m_id });
}

static AssetManager* g_asset_manager{nullptr};

AssetManager::AssetManager()
    : m_model(new QStandardItemModel(this))
{
    Q_ASSERT(!g_asset_manager);
    g_asset_manager = this;

    m_model->setItemRoleNames({
        { Qt::UserRole + 1, "asset" },
        { Qt::UserRole + 2, "weight" },
    });

    connect(Analytics::instance(), &Analytics::remoteConfigChanged, this, [this] {
        auto liquid_assets = Analytics::instance()->getRemoteConfigValue("liquid_assets").toArray();

        auto network = NetworkManager::instance()->network("liquid");

        for (const auto& value: liquid_assets) {
            const auto data = value.toObject();
            auto asset = assetWithId(data.value("id").toString());
            asset->setNetwork(network);
            asset->setIsAmp(data.value("amp").toBool(false));
            asset->setWeight(data.value("weight").toInt(0));
        }
    });

    for (const auto network : NetworkManager::instance()->networks()) {
        if (!network->data().value("mainnet").toBool()) continue;

        qDebug() << network->id() << network->canonicalId() << network->displayName() << network->key() << network->data().value("policy_asset");
        const auto id = network->data().value("policy_asset").toString(network->key());
        auto asset = assetWithId(id);
        asset->setNetwork(network);
        asset->setWeight(INT_MAX);
        asset->setName(network->displayName());
    }
//    Q_UNREACHABLE();

//    const auto policy_asset = data.value("policy_asset").toString(key.toString());
//    auto asset = AssetManager::instance()->assetWithId(policy_asset);
//    asset->setWeight(INT_MAX);
}

AssetManager::~AssetManager()
{
    g_asset_manager = nullptr;
}

AssetManager *AssetManager::instance()
{
    Q_ASSERT(g_asset_manager);
    return g_asset_manager;
}

AssetManager* AssetManager::create(QQmlEngine *, QJSEngine *engine)
{
    return AssetManager::instance();
}

Asset *AssetManager::assetWithId(const QString& id)
{
    Asset* asset = m_assets.value(id);
    if (!asset) {
        asset = new Asset(id, this);
        m_assets.insert(id, asset);
        m_model->appendRow(asset->item());
    }
    return asset;
}

AssetsModel::AssetsModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setSourceModel(AssetManager::instance()->model());
    setDynamicSortFilter(true);
    setSortRole(Qt::UserRole + 2);
    sort(0, Qt::DescendingOrder); // NOLINT(build/include_what_you_use)
}

void AssetsModel::setFilter(const QString& filter)
{
    if (m_filter == filter) return;
    m_filter = filter;
    emit filterChanged();
    invalidateRowsFilter();
}

void AssetsModel::setMinWeight(int min_weight)
{
    if (m_min_weight == min_weight) return;
    m_min_weight = min_weight;
    emit minWeightChanged();
    invalidateRowsFilter();
}

bool AssetsModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    const auto index = sourceModel()->index(source_row, 0, source_parent);
    const auto asset = index.data(Qt::UserRole + 1).value<Asset*>();

//    if (!asset->hasIcon()) return false;

    if (asset->weight() < m_min_weight) return false;

    if (!m_filter.isEmpty()) {
        if (!asset->name().contains(m_filter, Qt::CaseInsensitive)) return false;
    }

    return true;
}

//bool AssetsModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
//{
//    const auto asset_left = left.data(Qt::UserRole + 1).value<Asset*>();
//    const auto asset_right = right.data(Qt::UserRole + 1).value<Asset*>();

//    if (asset_left->weight() < asset_right->weight()) return true;
//    if (asset_left->weight() > asset_right->weight()) return false;

////    if (asset_left->hasData()) {

////    }

//    return QSortFilterProxyModel::lessThan(left, right);
//}
