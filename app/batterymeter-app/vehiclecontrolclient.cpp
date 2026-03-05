#include "vehiclecontrolclient.h"
#include <QDebug>
#include <QDateTime>
#include <functional>
#include <algorithm>

VehicleControlClient::VehicleControlClient(QObject *parent)
    : QObject(parent)
    , m_batteryLevel(0)
    , m_isCharging(false)
    , m_serviceAvailable(false)
    , m_filteredVoltage(0.0f)
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
        [this](std::string gear, uint16_t speed, uint16_t voltage, int16_t current, uint64_t timestamp) {
            this->onVehicleStateChanged(gear, speed, voltage, current, timestamp);
        }
    );
    
    qDebug() << "✅ Event subscriptions setup complete";
}

void VehicleControlClient::onVehicleStateChanged(std::string gear, uint16_t speed, uint16_t voltage, int16_t current, uint64_t timestamp)
{
    // EMA filter on voltage (alpha=0.1 → smooth, slow to react)
    float voltageV = voltage / 1000.0f;
    if (m_filteredVoltage == 0.0f)
        m_filteredVoltage = voltageV;  // Initialize on first reading
    else
        m_filteredVoltage = 0.1f * voltageV + 0.9f * m_filteredVoltage;

    // Convert filtered voltage to percentage (3S LiPo: 9.0V=0%, 12.6V=100%)
    float pct = (m_filteredVoltage - 9.0f) / (12.6f - 9.0f) * 100.0f;
    int newLevel = static_cast<int>(std::clamp(pct, 0.0f, 100.0f));

    // 2% dead zone: only update if change is significant (prevents integer boundary flickering)
    if (abs(newLevel - m_batteryLevel) >= 2) {
        m_batteryLevel = newLevel;
        emit batteryLevelChanged(m_batteryLevel);
    }

    // Charging detection: current > 100mA = charging
    bool charging = (current > 100);
    if (m_isCharging != charging) {
        m_isCharging = charging;
        emit isChargingChanged(m_isCharging);
    }

    qDebug() << "📡 [Event] vehicleStateChanged:"
             << "Voltage:" << voltage << "mV"
             << "Current:" << current << "mA"
             << "Battery:" << m_batteryLevel << "%"
             << "Charging:" << m_isCharging;
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
