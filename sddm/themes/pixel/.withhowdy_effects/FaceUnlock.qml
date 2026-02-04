import QtQuick 2.15
import QtQuick.Shapes 1.15

Item {
    id: root
    readonly property real localScale: Math.max(0.6, Math.min(1.6, Math.min(Screen.width, Screen.height) / 900))
    width: Math.round(120 * localScale)
    height: Math.round(120 * localScale)

    // Properties
    property string status: "idle" 
    property color colorScan: "#ffffff"
    property color colorVerified: "#ffffff"
    property color colorError: "#ff6b6b"

    property color currentColor: colorScan
    property real currentY: Math.round(30 * localScale)
    property real curveDepth: 0      

    // EYES - -
    Item {
        id: eyesContainer
        y: Math.round(25 * root.localScale); width: Math.round(70 * root.localScale); height: Math.round(20 * root.localScale)
        anchors.horizontalCenter: parent.horizontalCenter
        z: 2

        Rectangle { id: eyeLeft; width: Math.round(18 * root.localScale); height: Math.round(18 * root.localScale); radius: Math.round(9 * root.localScale); color: root.currentColor; anchors.left: parent.left; opacity: 0; scale: 0 }
        Rectangle { id: eyeRight; width: Math.round(18 * root.localScale); height: Math.round(18 * root.localScale); radius: Math.round(9 * root.localScale); color: root.currentColor; anchors.right: parent.right; opacity: 0; scale: 0 }
    }

    // Mouth :)
    Shape {
        id: mouthShape
        width: Math.round(80 * root.localScale); height: Math.round(60 * root.localScale)
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.status === "verified" ? Math.round(15 * root.localScale) : 0
        layer.enabled: true; layer.samples: 4

        ShapePath {
            strokeColor: root.currentColor; strokeWidth: Math.max(1, Math.round(10 * root.localScale)); fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            startX: Math.round(10 * root.localScale); startY: root.currentY - root.curveDepth
            PathQuad { controlX: Math.round(40 * root.localScale); controlY: root.currentY + root.curveDepth; x: Math.round(70 * root.localScale); y: root.currentY - root.curveDepth }
        }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    // ANIMATIONS 
    SequentialAnimation {
        running: root.status === "scanning"
        loops: Animation.Infinite; alwaysRunToEnd: false
        NumberAnimation { target: root; property: "currentY"; from: 20; to: 40; duration: 1000; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "currentY"; from: 40; to: 20; duration: 1000; easing.type: Easing.InOutSine }
    }

    states: [
        State {
            name: "idle"; when: root.status == "idle"
            PropertyChanges { target: root; currentColor: root.colorScan; curveDepth: 0; currentY: 30 }
            PropertyChanges { target: eyeLeft; opacity: 0; scale: 0 }
            PropertyChanges { target: eyeRight; opacity: 0; scale: 0 }
        },
        State {
            name: "scanning"; when: root.status == "scanning"
            PropertyChanges { target: root; currentColor: root.colorScan; curveDepth: 0 }
            PropertyChanges { target: eyeLeft; opacity: 0; scale: 0 }
            PropertyChanges { target: eyeRight; opacity: 0; scale: 0 }
        },
        State {
            name: "verified"; when: root.status == "verified"
            PropertyChanges { target: root; currentColor: root.colorVerified; currentY: 30; curveDepth: 15 }
            PropertyChanges { target: eyeLeft; opacity: 1; scale: 1 }
        },
        State {
            name: "failed"; when: root.status == "failed"
            PropertyChanges { target: root; currentColor: root.colorError; currentY: 30; curveDepth: -5 }
        }
    ]

    transitions: [
        Transition {
            from: "*"; to: "verified"
            ParallelAnimation {
                ColorAnimation { duration: 300 }
                NumberAnimation { properties: "currentY, curveDepth"; duration: 400; easing.type: Easing.OutBack }
                NumberAnimation { target: eyeLeft; properties: "opacity, scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
                NumberAnimation { target: eyeRight; properties: "opacity, scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
            }
            SequentialAnimation {
                PauseAnimation { duration: 400 } // Wait for smile
                ParallelAnimation {
                    NumberAnimation { target: eyeRight; property: "height"; to: 4; duration: 150 }
                    NumberAnimation { target: eyeRight; property: "radius"; to: 2; duration: 150 }
                }
            }
        },
        Transition {
            from: "*"; to: "failed"
            ParallelAnimation {
                ColorAnimation { duration: 200 }
                NumberAnimation { properties: "curveDepth"; duration: 200 }
            }
        }
    ]
}