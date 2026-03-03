import QtQuick 2.15
import QtQuick.Window 2.15
import Design 1.0

Window {
    id: mainWindow
    width: 280
    height: 600
    visible: true
    title: "Gear State"
    color: Constants.backgroundColor

    // Main gear state container
    Item {
        id: gearSection
        anchors.fill: parent
        
        // Bind to vehicleClient gearState
        property string currentGear: vehicleClient.gearState
        
        // Gear gauge container (centered)
        Item {
            id: gaugeContainer
            width: 280
            height: 280
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -10
            
            // Background gauge decoration (outer ring)
            Image {
                id: gaugeSpeedometer_Ticks_outer
                anchors.fill: parent
                source: "qrc:/images/GaugeSpeedometer_Ticks2.png"
                fillMode: Image.PreserveAspectFit
            }

            // Background gauge decoration (inner ring)
            Image {
                id: gaugeSpeedometer_Ticks_inner
                anchors.centerIn: parent
                source: "qrc:/images/GaugeSpeedometer_Ticks1.png"
                fillMode: Image.PreserveAspectFit
            }
            
            // Gear letter display (centered in gauge)
            Text {
                id: gearText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 5
                width: 150
                height: 150
                color: "#ffffff"
                text: gearSection.currentGear
                font.pixelSize: 100
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    
    // Connections to vehicleClient
    Connections {
        target: vehicleClient
        function onGearStateChanged() {
            console.log("📡 Gear changed:", vehicleClient.gearState)
        }
    }
}
