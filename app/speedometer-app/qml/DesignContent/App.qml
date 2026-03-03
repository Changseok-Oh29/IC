import QtQuick 2.15
import QtQuick.Window 2.15
import Design 1.0

Window {
    id: mainWindow
    width: 400
    height: 600
    visible: true
    title: "Speedometer"
    color: Constants.backgroundColor

    // Main speedometer container
    Item {
        id: speedometerSection
        anchors.fill: parent
        
        // Bind to vehicleClient speed
        property int currentSpeed: vehicleClient.speed
        
        // Speedometer gauge container (centered)
        Item {
            id: gaugeContainer
            width: 400
            height: 400
            anchors.centerIn: parent
            
            // Background speed gauge (rotated 45°)
            Image {
                id: gauge_Speed
                anchors.centerIn: parent
                width: 400
                height: 400
                source: "qrc:/images/Gauge_Speed.png"
                rotation: 45
                fillMode: Image.PreserveAspectFit
            }

            // Speedometer tick marks
            Image {
                id: gaugeSpeedometer_Ticks2
                anchors.centerIn: parent
                width: 259
                height: 278
                source: "qrc:/images/GaugeSpeedometer_Ticks2.png"
                fillMode: Image.PreserveAspectFit
            }

            // Speed needle (rotates based on speed)
            Image {
                id: gaugeNeedleBig
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -49
                width: 160
                height: 66
                source: "qrc:/images/gaugeNeedleBig.png"
                fillMode: Image.PreserveAspectFit

                transform: Rotation {
                    id: needleRotation
                    origin.x: 130
                    origin.y: 33
                    angle: -45 + (speedometerSection.currentSpeed * 1.125)
                    
                    Behavior on angle {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
            
            // Bottom panel overlay (INSIDE gaugeContainer, at bottom)
            Image {
                id: bottomPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                width: parent.width * 1.74  // 697px scaled for 400px gauge
                source: "qrc:/images/BottomPanel.png"
                fillMode: Image.PreserveAspectFit
                z: 5
            }

            // Speed value display
            Text {
                id: speedText
                anchors.horizontalCenter: bottomPanel.horizontalCenter
                anchors.verticalCenter: bottomPanel.verticalCenter
                width: 188
                height: 81
                color: "#ffffff"
                text: speedometerSection.currentSpeed.toString()
                font.pixelSize: 30
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                z: 10
            }
        }
    }
    
    // Connections to vehicleClient
    Connections {
        target: vehicleClient
        function onSpeedChanged() {
            console.log("📡 Speed changed:", vehicleClient.speed, "km/h")
        }
    }
}
