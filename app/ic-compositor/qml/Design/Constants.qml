pragma Singleton
import QtQuick 2.15

QtObject {
    // Display dimensions
    readonly property int displayWidth: 1024
    readonly property int displayHeight: 600
    
    // Section dimensions
    readonly property int gearStateWidth: 280
    readonly property int gearStateHeight: 400
    
    readonly property int speedometerWidth: 400
    readonly property int speedometerHeight: 400
    
    readonly property int batteryMeterWidth: 280
    readonly property int batteryMeterHeight: 400
    
    // Colors
    readonly property color backgroundColor: "#000000"
    readonly property color separatorColor: "#1a1a1a"
    readonly property color placeholderColor: "#0d0d0d"
    readonly property color connectedColor: "#57e389"
    readonly property color disconnectedColor: "#ff4444"
}
