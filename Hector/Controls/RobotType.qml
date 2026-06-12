pragma Singleton
import QtQuick 2.0

// Robot locomotion type, shared by the 2D robot views (UGV2DView, RobotOrientationView).
// Mirrors the type set a robot announcement can declare (cf. Hector.MultiRobot Robot.Type).
// Only Wheeled and Tracked are rendered; the rest let callers recognise/hide the view.
QtObject {
  enum Value {
    Unknown,
    Wheeled,
    Tracked,
    Legged,
    Quadrotor
  }

  //! Maps an announcement type string ("wheeled" | "tracked" | ...) to a RobotType value.
  //! Unrecognised/empty strings map to RobotType.Unknown.
  function fromString(name) {
    switch (name) {
      case "wheeled":   return RobotType.Wheeled
      case "tracked":   return RobotType.Tracked
      case "legged":    return RobotType.Legged
      case "quadrotor": return RobotType.Quadrotor
      default:          return RobotType.Unknown
    }
  }
}
