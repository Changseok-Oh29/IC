#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include "vehiclecontrolclient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName("appSpeedometer");
    app.setApplicationDisplayName("Speedometer");
    
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Speedometer Application";
    qDebug() << "App ID: appSpeedometer";
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
