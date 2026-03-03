#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include "vehiclecontrolclient.h"

int main(int argc, char *argv[])
{
    // Simple, clean - environment set by shell script
    QGuiApplication app(argc, argv);

    // Only set application name for compositor recognition
    app.setApplicationName("appGearState");
    app.setApplicationDisplayName("Gear State");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "GearState Application";
    qDebug() << "App ID: appGearState";
    qDebug() << "═══════════════════════════════════════════════════════";

    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:/");
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/Design/Constants.qml")),
                             "Design", 1, 0, "Constants");

    VehicleControlClient *vehicleClient = new VehicleControlClient();
    engine.rootContext()->setContextProperty("vehicleClient", vehicleClient);

    const QUrl url(QStringLiteral("qrc:/DesignContent/App.qml"));
    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML!";
        return -1;
    }

    qDebug() << "✓ Application loaded";
    
    return app.exec();
}
