// InvertedCorner.qml
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    enum Corner {
        TopLeft,
        TopRight,
        BottomRight,
        BottomLeft
    }

    property color color: "#009999"
    property real radius: 8
    property int corner: InvertedCorner.TopLeft

    width: radius
    height: radius

    // [start, arcTarget, lineTarget] - path closes back to start automatically
    readonly property var _pts: {
        const w = radius, h = radius;
        switch (corner) {
            case InvertedCorner.BottomRight:     return [[w, 0], [0, h], [w, h]];
            case InvertedCorner.BottomLeft:    return [[w, h], [0, 0], [0, h]];
            case InvertedCorner.TopLeft: return [[0, h], [w, 0], [0, 0]];
            default:                         return [[0, 0], [w, h], [w, 0]]; // BottomLeft
        }
    }
    Behavior on anchors.topMargin {
        animation: defaultCurve
    }
    
    Behavior on radius {
        animation: defaultCurve
    }
   
    NumberAnimation {
        id: defaultCurve

        duration: 200
        easing: Easing.Linear
    }

    Shape {
        anchors.fill: parent

        ShapePath {
            fillColor: root.color
            strokeColor: root.color
            strokeWidth: 0.25

            startX: root._pts[0][0]
            startY: root._pts[0][1]

            PathArc {
                x: root._pts[1][0]
                y: root._pts[1][1]
                radiusX: root.radius
                radiusY: root.radius
                useLargeArc: false
            }

            PathLine {
                x: root._pts[2][0]
                y: root._pts[2][1]
            }

            PathLine {
                x: root._pts[0][0]
                y: root._pts[0][1]
            }
        }
    }
}