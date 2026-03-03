pragma Singleton
import QtQuick 2.15

QtObject {
    // Display dimensions (400x400 speedometer section)
    readonly property int width: 400
    readonly property int height: 400

    property string relativeFontDirectory: "fonts"

    // Speedometer-specific constants
    readonly property int gaugeSize: 400
    readonly property int needleOriginX: 130
    readonly property int needleOriginY: 33
    readonly property real speedToAngleRatio: 1.125  // Speed (0-240) to angle conversion
    readonly property int minAngle: -45
    readonly property int maxSpeed: 240
    
    // Colors
    readonly property color backgroundColor: "#000000"
    readonly property color speedTextColor: "#ffffff"
    readonly property color labelColor: "#730000"
    
    // Fonts
    readonly property font font: Qt.font({
        family: "Arial",
        pixelSize: 20
    })

    readonly property font largeFont: Qt.font({
        family: "Arial",
        pixelSize: 32
    })
    
    readonly property font speedFont: Qt.font({
        family: "Arial",
        pixelSize: 30,
        bold: true
    })
}

