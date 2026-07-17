# Hector QML Controls

This package contains QML components used by Team Hector that can be easily used in other projects and applications.

You can find more controls that are more strongly integrated into our software stack and how these controls are used in our human-robot operator interface in the [repo for our user interface](https://github.com/tu-darmstadt-ros-pkg/hector_user_interface).


## Usage

Download in your catkin source folder, build and then re-source your workspace.
After that every QML application with your workspace in its launch environment should be able to import the controls as follows:

```qml
import Hector.Controls 1.0 // for controls
import Hector.Icons 1.0 // for icons
import Hector.Utils 1.0 // for utility classes and singletons
```


## Attribution

This package is MIT licensed (see [LICENSE](LICENSE)) with the exception of the gamepad artwork in
`Hector/Controls/svgs`, which is licensed separately:

> Button Icons and Controls by Zacksly (CC BY 3.0 Licensed | [zacksly.itch.io](https://zacksly.itch.io))

Projects redistributing these assets must keep this attribution.
