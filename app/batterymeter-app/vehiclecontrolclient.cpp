#include "vehiclecontrolclient.h"
#include <QDebug>
#include <QDateTime>
#include <functional>

VehicleControlClient::VehicleControlClient(QObject *parent)
    : QObject(parent)
    , m_batteryLevel(0)
    , m_serviceAvailable(false)
{
    qDebug() << "VehicleControlClient (BatteryMeter) created";
    
    // Auto-connect to service
    connectToService();
}

VehicleControlClient::~VehicleControlClient()
{
    disconnectFromService();
    qDebug() << "VehicleControlClient destroyed";
}

void VehicleControlClient::connectToService()
{
    qDebug() << "🔌 Connecting to VehicleControl service...";
    
    // Get CommonAPI runtime
    m_runtime = CommonAPI::Runtime::get();
    if (!m_runtime) {
        qCritical() << "❌ Failed to get CommonAPI runtime!";
        emit serviceAvailableChanged(false);
        return;
    }
    
    // Build proxy
    const std::string domain = "local";
    const std::string instance = "vehiclecontrol.VehicleControl";
    const std::string connection = "BatteryMeter_client";
    
    m_proxy = m_runtime->buildProxy<VehicleControlProxy>(domain, instance, connection);
    
    if (!m_proxy) {
        qCritical() << "❌ Failed to build VehicleControl proxy!";
        emit serviceAvailableChanged(false);
        return;
    }
    
    qDebug() << "✅ Proxy created successfully";
    
    // Subscribe to availability status
    m_proxy->getProxyStatusEvent().subscribe(
        std::bind(&VehicleControlClient::onAvailabilityChanged, this, std::placeholders::_1)
    );
    
    // Setup event subscriptions
    setupEventSubscriptions();
    
    qDebug() << "✅ Connected to VehicleControl service";
    qDebug() << "   Domain:" << QString::fromStdString(domain);
    qDebug() << "   Instance:" << QString::fromStdString(instance);
}

void VehicleControlClient::disconnectFromService()
{
    if (m_proxy) {
        qDebug() << "🔌 Disconnecting from VehicleControl service...";
        m_proxy.reset();
        m_serviceAvailable = false;
        emit serviceAvailableChanged(false);
    }
}

void VehicleControlClient::setupEventSubscriptions()
{
    if (!m_proxy) {
        qWarning() << "Cannot setup subscriptions: proxy is null";
        return;
    }
    
    qDebug() << "📡 Subscribing to VehicleControl events...";
    
    // Subscribe to vehicleStateChanged event
    m_proxy->getVehicleStateChangedEvent().subscribe(
        [this](std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp) {
            this->onVehicleStateChanged(gear, speed, battery, timestamp);
        }
    );
    
    qDebug() << "✅ Event subscriptions setup complete";
}

void VehicleControlClient::onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp)
{
    // Update battery level
    if (m_batteryLevel != battery) {
        m_batteryLevel = battery;
        emit batteryLevelChanged(m_batteryLevel);
        
        qDebug() << "📡 [Event] vehicleStateChanged:"
                 << "Gear:" << QString::fromStdString(gear)
                 << "Speed:" << speed << "km/h"
                 << "Battery:" << m_batteryLevel << "%";
    }
}

void VehicleControlClient::onAvailabilityChanged(CommonAPI::AvailabilityStatus status)
{
    bool wasAvailable = m_serviceAvailable;
    m_serviceAvailable = (status == CommonAPI::AvailabilityStatus::AVAILABLE);

    if (m_serviceAvailable != wasAvailable) {
        qDebug() << "🔗 Service availability changed:"
                  << (m_serviceAvailable ? "AVAILABLE" : "NOT AVAILABLE");
        emit serviceAvailableChanged(m_serviceAvailable);
    }

    if (m_serviceAvailable) {
        qDebug() << "✅ VehicleControl service is now available!";
        // Start simulation when service becomes available
        startSimulation();
    } else {
        qWarning() << "⚠️  VehicleControl service is not available";
    }
}

void VehicleControlClient::startSimulation()
{
    qDebug() << "🚀 startSimulation() called";

    if (!m_proxy || !m_serviceAvailable) {
        qWarning() << "Cannot start simulation: proxy not available";
        return;
    }

    qDebug() << "🚗 Starting VehicleControl simulation by setting gear to REVERSE";

    // Call the setGearPosition RPC to start the simulation
    qDebug() << "🔧 Calling setGearPosition with gear='R'";
    CommonAPI::CallStatus callStatus;
    bool success;
    m_proxy->setGearPosition("R", callStatus, success);

    qDebug() << "🔧 RPC call completed - callStatus:" << (int)callStatus << "success:" << success;

    if (callStatus == CommonAPI::CallStatus::SUCCESS && success) {
        qDebug() << "✅ Gear set to REVERSE - simulation should start";
    } else {
        qWarning() << "❌ Failed to set gear to REVERSE - callStatus:" << (int)callStatus << "success:" << success;
    }
}
