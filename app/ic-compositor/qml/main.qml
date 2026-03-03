import QtQuick 2.15
import QtQuick.Window 2.15
import QtWayland.Compositor 1.3

/*
 * IC_Compositor - Nested Wayland Compositor (Industrial Kiosk Mode)
 *
 * Architecture:
 * - Nested compositor connecting to Weston (wayland-1)
 * - Creates wayland-2 socket for IC apps
 * - Fixed layout, no window decorations (Kiosk mode)
 * - Index-based surface routing for IC apps
 */

WaylandCompositor {
    id: compositor

    // Create Wayland server socket for IC apps
    // Weston uses wayland-1, HU uses wayland-3, so we use wayland-2
    socketName: "wayland-2"

    WaylandOutput {
        id: output
        compositor: compositor
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            width: 1024
            height: 600
            visible: true
            title: "IC_Compositor"
            color: "#000000"
            
            // Kiosk mode: No window decorations, fixed position
            // Weston will manage this as a fullscreen client

            Row {
                anchors.fill: parent
                spacing: 0

                ApplicationLayer {
                    id: layerGearState
                    width: 280
                    height: 600
                    appId: "appGearState"
                }

                ApplicationLayer {
                    id: layerSpeedometer
                    width: 400
                    height: 600
                    appId: "appSpeedometer"
                }

                ApplicationLayer {
                    id: layerBattery
                    width: 280
                    height: 600
                    appId: "appBatteryMeter"
                }
            }
        }
    }

    XdgShell {
        id: xdgShell
        property int surfaceCount: 0
        onToplevelCreated: function(toplevel, xdgSurface) {
            console.log("[XDG] Toplevel " + xdgShell.surfaceCount)
            // Use index-based routing since app IDs aren't available
            var size = Qt.size(1024, 600)
            var layer = null
            
            if (xdgShell.surfaceCount === 0) {
                size = Qt.size(280, 600)  // GearState
                layer = "GearState"
            } else if (xdgShell.surfaceCount === 1) {
                size = Qt.size(400, 600)  // Speedometer
                layer = "Speedometer"
            } else if (xdgShell.surfaceCount === 2) {
                size = Qt.size(280, 600)  // BatteryMeter
                layer = "BatteryMeter"
            }
            
            console.log("[XDG-SIZE-" + layer + "] " + size.width + "x" + size.height)
            toplevel.sendFullscreen(size)
            assignSurfaceByIndex(xdgShell.surfaceCount, xdgSurface)
            xdgShell.surfaceCount++
        }
    }

    WlShell {
        id: wlShell
        property int surfaceCount: 0
        onWlShellSurfaceCreated: function(wlSurface) {
            console.log("[WLSHELL] Surface " + wlShell.surfaceCount)
            assignSurfaceByIndex(wlShell.surfaceCount, wlSurface)
            wlShell.surfaceCount++
        }
    }

    function assignSurfaceByAppId(appId, surface) {
        console.log("[ASSIGN-APP] " + appId)
        if (appId.indexOf("GearState") !== -1) {
            layerGearState.setSurface(surface)
        } else if (appId.indexOf("Speedometer") !== -1) {
            layerSpeedometer.setSurface(surface)
        } else if (appId.indexOf("BatteryMeter") !== -1) {
            layerBattery.setSurface(surface)
        }
    }

    function assignSurfaceByIndex(idx, surface) {
        var apps = [layerGearState, layerSpeedometer, layerBattery]
        if (idx < apps.length) {
            console.log("[ASSIGN-INDEX] " + idx)
            apps[idx].setSurface(surface)
        }
    }

    component ApplicationLayer: Rectangle {
        property string appId: ""
        
        color: "#000000"

        ShellSurfaceItem {
            id: surfaceItem
            anchors.fill: parent
            touchEventsEnabled: true
            z: 100
            onShellSurfaceChanged: {
                console.log("[SHELL-SURFACE-CHANGE] " + appId + " surface null? " + (shellSurface === null))
            }
        }

        Text {
            anchors.centerIn: parent
            visible: surfaceItem.shellSurface === null
            color: "#444444"
            font.pixelSize: 12
            text: appId + " (no surface)"
            z: 5
        }

        function setSurface(surface) {
            if (surface) {
                console.log("[SET-SURFACE] " + appId + " assigning surface")
                surfaceItem.shellSurface = surface
                console.log("[SET-SURFACE-DONE] " + appId + " surface is now: " + (surfaceItem.shellSurface ? "valid" : "null"))
            }
        }
    }
}
