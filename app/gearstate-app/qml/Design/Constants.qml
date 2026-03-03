pragma Singleton
import QtQuick 2.15

QtObject {
    // Display dimensions (280x400 gear section)
    readonly property int width: 280
    readonly property int height: 400

    property string relativeFontDirectory: "fonts"

    // Gear-specific constants
    readonly property int gaugeSize: 280
    
    // Colors
    readonly property color backgroundColor: "#000000"
    readonly property color gearTextColor: "#ffffff"
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
    
    readonly property font gearFont: Qt.font({
        family: "Arial",
        pixelSize: 100,
        bold: true
    })
}
