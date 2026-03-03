#ifndef VEHICLECONTROLCLIENT_H
#define VEHICLECONTROLCLIENT_H

#include <QObject>
#include <QString>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/vehiclecontrol/VehicleControlProxy.hpp>

using namespace v1::vehiclecontrol;

/**
 * @brief Client for VehicleControl service (vsomeip communication)
 *
 * This class connects to the VehicleControl service running on ECU1
 * and provides speed updates via event subscriptions.
 */
class VehicleControlClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gearState READ gearState NOTIFY gearStateChanged)
    Q_PROPERTY(int speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
    Q_PROPERTY(bool serviceAvailable READ serviceAvailable NOTIFY serviceAvailableChanged)

public:
    explicit VehicleControlClient(QObject *parent = nullptr);
    virtual ~VehicleControlClient();

    // Property getters
    QString gearState() const { return m_gearState; }
    int speed() const { return m_speed; }
    int batteryLevel() const { return m_batteryLevel; }
    bool serviceAvailable() const { return m_serviceAvailable; }

public slots:
    // Connection management
    void connectToService();
    void disconnectFromService();
    void startSimulation();

signals:
    void gearStateChanged(QString gear);
    void speedChanged(int speed);
    void batteryLevelChanged(int level);
    void serviceAvailableChanged(bool available);

private:
    // CommonAPI proxy
    std::shared_ptr<VehicleControlProxy<>> m_proxy;
    std::shared_ptr<CommonAPI::Runtime> m_runtime;

    // Current state
    QString m_gearState;
    int m_speed;
    int m_batteryLevel;
    bool m_serviceAvailable;

    // Event subscriptions
    void setupEventSubscriptions();
    void onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp);
    void onAvailabilityChanged(CommonAPI::AvailabilityStatus status);
};

#endif // VEHICLECONTROLCLIENT_H
