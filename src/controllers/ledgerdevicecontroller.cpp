#include "device.h"
#include "ga.h"
#include "json.h"
#include "ledgerdevicecontroller.h"
#include "network.h"
#include "networkmanager.h"
#include "resolver.h"
#include "util.h"
#include "wallet.h"
#include "walletmanager.h"

#include "handlers/registeruserhandler.h"
#include "handlers/loginhandler.h"

LedgerDeviceController::LedgerDeviceController(QObject* parent)
    : QObject(parent)
{
}

void LedgerDeviceController::setDevice(Device *device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged(m_device);

    if (m_device) {
        QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
    }
}

Network* LedgerDeviceController::networkFromAppName(const QString& app_name)
{
    QString id;
    if (app_name == "Bitcoin") id = "mainnet";
    if (app_name == "Bitcoin Test") id = "testnet";
    if (app_name == "Liquid") id = "liquid";
    return id.isEmpty() ? nullptr : NetworkManager::instance()->network(id);
}

void LedgerDeviceController::initialize()
{
    auto cmd = new GetAppNameCommand(m_device);
    connect(cmd, &Command::finished, this, [this, cmd] {
        m_network = LedgerDeviceController::networkFromAppName(cmd->m_name);
        emit networkChanged(m_network);
        if (!m_network) {
            Q_ASSERT(cmd->m_name.indexOf("OLOS") >= 0);
            QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
            return;
        }

        const auto name = m_device->name().toLocal8Bit();
        m_device_details = {{
            "device", QJsonObject({
                { "name", name.constData() },
                { "supports_arbitrary_scripts", true },
                { "supports_low_r", false },
                { "supports_liquid", 1 }
            })
        }};

        m_wallet = new Wallet;
        m_wallet->m_device = m_device;
        m_wallet->setNetwork(m_network);

        login();
    });
    connect(cmd, &Command::error, this, [this] {
        QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
    });
    cmd->exec();
}

void LedgerDeviceController::login()
{
    auto log_level = QString::fromLocal8Bit(qgetenv("GREEN_GDK_LOG_LEVEL"));
    if (log_level.isEmpty()) log_level = "info";

    QJsonObject params{
        { "name", m_network->id() },
        { "log_level", log_level },
        { "use_tor", false },
    };

    m_wallet->createSession();
    // TODO: Add ConnectHandler
    GA_connect(m_wallet->m_session, Json::fromObject(params));

    auto register_user_handler = new RegisterUserHandler(m_wallet, m_device_details);
    auto login_handler = new LoginHandler(m_wallet, m_device_details);
    connect(register_user_handler, &Handler::done, this, [login_handler] {
        login_handler->exec();
    });
    connect(register_user_handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    connect(login_handler, &Handler::done, this, [this] {
        m_wallet->setSession();
        WalletManager::instance()->addWallet(m_wallet);

        m_progress = 1;
        emit progressChanged(m_progress);

        // TODO: should the controller decide wallet lifetime?
        auto w = m_wallet;
        connect(m_device, &QObject::destroyed, this, [w] {
            WalletManager::instance()->removeWallet(w);
            delete w;
        });
    });
    connect(login_handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    register_user_handler->exec();
}
