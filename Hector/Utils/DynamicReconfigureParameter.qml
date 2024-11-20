import QtQuick 2.3
import Ros 1.0

Object {
  id: root
  
  enum Type {
    Uninitialized,
    Bool,
    Int,
    Double,
    String,
    Enum
  }

  property string namespace
  onNamespaceChanged: d.loadParameter()
  property string name
  onNameChanged: d.loadParameter()

  readonly property int type: d.type
  readonly property var defaultValue: d.defaultValue
  readonly property var min: d.min
  readonly property var max: d.max
  //! Enum options as list of objects: {name, value, description}
  readonly property var enumOptions: d.enumOptions

  //! When using enum options set it to the value of the enum option
  property var value
  onValueChanged: d.updateValue(value)

  Subscriber {
    id: descriptionSubscriber
    topic: namespace + "/parameter_descriptions"
    onNewMessage: {
      let parameter = null
      for (let group of descriptionSubscriber.message.groups.toArray()) {
        for (let param of group.parameters.toArray()) {
          if (param.name != root.name) continue
          parameter = param
          d.valueType = d.parseType(param.type)
          if (param.edit_method != "" && "enum" in d.parseEditMethod(param.edit_method)) {
            d.type = DynamicReconfigureParameter.Enum
          } else {
            d.type = d.valueType
          }
          break
        }
        if (parameter) break
      }
      if (parameter == null) {
        Ros.warn("Could not find parameter '" + root.name + "' in namespace '" + root.namespace + "'!")
        return
      }
      let member = d.getMemberForType(d.valueType)
      let index = -1
      for (let i = 0; i < descriptionSubscriber.message.min[member].length; ++i) {
        if (descriptionSubscriber.message.min[member].at(i).name != root.name) continue
        index = i
        break
      }
      if (index == -1) {
        d.min = null
        d.max = null
        d.defaultValue = null
        d.enumOptions = null
        return
      }
      d.min = descriptionSubscriber.message.min[member].at(index).value
      d.max = descriptionSubscriber.message.max[member].at(index).value
      d.defaultValue = descriptionSubscriber.message.dflt[member].at(index).value
      if (root.value == null) {
        d.value = d.defaultValue
        root.value = d.defaultValue
      }
      if (type != DynamicReconfigureParameter.Enum) return
      let editMethod = d.parseEditMethod(parameter.edit_method)
      let enumOptions = []
      for (let option of editMethod.enum) {
        enumOptions.push({name: option.name, value: option.value, type: d.parseType(option.type), description: option.description || ''})
      }
      d.enumOptions = enumOptions
    }
  }

  Subscriber {
    topic: namespace + "/parameter_updates"
    running: root.type != DynamicReconfigureParameter.Uninitialized
    onNewMessage: {
      if (root.type == DynamicReconfigureParameter.Uninitialized) return
      let values = message[d.getMemberForType(d.valueType)]
      for (let i = 0; i < values.length; ++i) {
        if (values.at(i).name !== root.name) continue
        d.value = values.at(i).value
        root.value = d.value
      }
    }
  }

  QtObject {
    id: d

    property int type: DynamicReconfigureParameter.Uninitialized
    property int valueType: DynamicReconfigureParameter.Uninitialized
    property var defaultValue: null
    property var min: null
    property var max: null
    property var enumOptions: []
    property var value: 0

    function parseEditMethod(method) {
      const regex = new RegExp(/('(?=(,\s*')))|('(?=:))|((?!([:,]\s*))')|((?!{)')|('(?=}))/g)
      return JSON.parse(method.replace(regex, '"'))
    }

    function parseType(typeName) {
      switch (typeName) {
        case "bool": return DynamicReconfigureParameter.Bool
        case "double": return DynamicReconfigureParameter.Double
        case "str": return DynamicReconfigureParameter.String
        case "int": return DynamicReconfigureParameter.Int
      }
    }

    function loadParameter() {
      if (!root.namespace || !root.param) return
      return
      Service.callAsync(root.namespace + "/set_parameters", "dynamic_reconfigure/Reconfigure", {}, function (result) {
        for (let key of ["bools", "ints", "strs", "doubles"]) {
          let values = result.config[key]
          for (let i = 0; i < values.length; ++i) {
            if (values.at(i).name !== root.name) continue
            d.value = values.at(i).value
            root.value = d.value
          }
        }
      })
    }

    function updateValue(val) {
      switch (root.type) {
        case DynamicReconfigureParameter.Bool:
          val = !!val
          break
        case DynamicReconfigureParameter.Int:
          val = Math.round(val)
          break
        case DynamicReconfigureParameter.Uninitialized:
          return
      }
      if (val == d.value) return
      let req = {config: {}}
      req.config[d.getMemberForType(d.valueType)] = [{name: root.name, value: val}]
      Service.callAsync(root.namespace + "/set_parameters", "dynamic_reconfigure/Reconfigure", req, function (result) {
        if (!result) {
          Ros.warn("Failed to update parameter '" + root.name + "' in namespace '" + root.namespace + "' with value: " + val)
          return
        }
        d.value = val
      })
    }

    function getMemberForType(type) {
      switch (type) {
        case DynamicReconfigureParameter.Enum:
          throw Error("There is no member for enum type. This should be called with the value type.")
        case DynamicReconfigureParameter.Int: return "ints"
        case DynamicReconfigureParameter.Double: return "doubles"
        case DynamicReconfigureParameter.String: return "strs"
        case DynamicReconfigureParameter.Bool: return "bools"
      }
      throw Error("Invalid type: " + type)
    }
  }
}
