pragma Singleton
import QtQuick 2.15

QtObject {
    // Display dimensions (280x400 battery section)
    readonly property int width: 280
    readonly property int height: 400

    property string relativeFontDirectory: "fonts"

    // Battery-specific constants
    readonly property int batteryIconWidth: 120
    readonly property int batteryFillWidth: 68
    readonly property int batteryFillMaxHeight: 110
    readonly property int batteryGaugeSize: 280
    
    // Colors
    readonly property color backgroundColor: "#000000"
    readonly property color labelColor: "#730000"
    readonly property color textColor: "#ffffff"
    readonly property color batteryLowColor: "#ff4444"      // Red ≤20%
    readonly property color batteryMediumColor: "#ffaa33"   // Orange ≤60%
    readonly property color batteryHighColor: "#57e389"     // Green >60%
    
    // Fonts
    readonly property font font: Qt.font({
        family: "Arial", 
        pixelSize: 20
    })

    readonly property font largeFont: Qt.font({
        family: "Arial",
        pixelSize: 32
    })
    
    readonly property font batteryPercentFont: Qt.font({
        family: "Arial",
        pixelSize: 25,
        bold: true
    })
}
