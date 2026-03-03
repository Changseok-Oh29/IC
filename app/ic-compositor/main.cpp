#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════
    // IC_Compositor - Nested Wayland Compositor (Kiosk Mode)
    // ═══════════════════════════════════════════════════════
    // IMPORTANT: IC_Compositor runs as a NESTED Wayland compositor
    // - Connects to Weston (wayland-1) as a client
    // - Creates sub-compositor socket (wayland-2) for IC apps
    // - Fixed layout, no window decorations (industrial mode)
    
    // Set platform to Wayland (connect to Weston)
    qputenv("QT_QPA_PLATFORM", "wayland");

    // Disable window decorations (Kiosk mode)
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // Ensure XDG shell is used
    qputenv("QT_WAYLAND_SHELL_INTEGRATION", "xdg-shell");

    // Create XDG_RUNTIME_DIR if not set
    if (qgetenv("XDG_RUNTIME_DIR").isEmpty()) {
        qputenv("XDG_RUNTIME_DIR", "/tmp/xdg");
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName("IC_Compositor");
    app.setOrganizationName("IVI");

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "IC Compositor - Nested Wayland Compositor (Kiosk Mode)";
    qDebug() << "Display: 1024x600 (Instrument Cluster)";
    qDebug() << "Shell: XDG Shell (Fixed Layout)";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Display Platform:" << app.platformName();
    qDebug() << "Parent Compositor:" << qgetenv("WAYLAND_DISPLAY");
    qDebug() << "";
    qDebug() << "📋 Role: Nested Wayland Compositor";
    qDebug() << "   - Client of Weston (wayland-0)";
    qDebug() << "   - Creates wayland-2 socket for IC apps";
    qDebug() << "   - Fixed position, no user interaction";
    qDebug() << "   - Index-based surface routing";
    qDebug() << "═══════════════════════════════════════════════════════";

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load compositor QML!";
        return -1;
    }

    qDebug() << "✓ Compositor initialized";
    qDebug() << "✓ Listening for XDG Shell applications...";
    qDebug() << "═══════════════════════════════════════════════════════";

    return app.exec();
}
