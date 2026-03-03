import QtQuick 2.15
import QtQuick.Window 2.15
import Design 1.0

Window {
    id: mainWindow
    width: 280
    height: 600
    visible: true
    title: "Battery Meter"
    color: Constants.backgroundColor

    // Main battery section container
    Item {
        id: batterySection
        anchors.fill: parent
        
        // Bind to vehicleClient batteryLevel
        property int batteryLevel: vehicleClient.batteryLevel
        
        // Gauge container (centered)
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
            
            // Battery icon and fill container (centered in gauge)
            Item {
                id: batteryIconContainer
                width: 120
                height: 180
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -10
                
                // Battery fill rectangle (grows from bottom)
                Rectangle {
                    id: battery_fill
                    width: 68
                    height: 110 * batterySection.batteryLevel / 100
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 35
                    z: 1

                    color: {
                        if (batterySection.batteryLevel <= 20)
                            return Constants.batteryLowColor
                        else if (batterySection.batteryLevel <= 60)
                            return Constants.batteryMediumColor
                        else
                            return Constants.batteryHighColor
                    }
                    
                    radius: 2
                    
                    Behavior on height {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutQuad
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }

                // Battery outline icon (overlay)
                Image {
                    id: battery_outline_icon
                    anchors.centerIn: parent
                    width: parent.width
                    source: "qrc:/images/battery_outline_icon.png"
                    fillMode: Image.PreserveAspectFit
                    z: 2
                }

                // Battery percentage text (centered on icon)
                Text {
                    id: battery_text
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -5
                    font: Constants.batteryPercentFont
                    color: Constants.textColor
                    text: batterySection.batteryLevel + "%"
                    z: 3
                }
            }
        }
    }
}
