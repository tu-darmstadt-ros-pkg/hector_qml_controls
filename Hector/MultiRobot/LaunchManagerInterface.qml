import QtQuick 2.3
import Ros2 1.0
import Hector.Actions 1.0
import Hector.Utils 1.0

Object {
  id: root
  enum Status {
    Unknown,
    Loading,
    Active,
    Idle,
    Error
  }
  property string name: ""
  property string namespace: ""
  property string config: ""
  // The names of the hosts this launch manager can launch on
  property var hosts: ListModel {}
  // The running components with status per host. Each entry is an object {host: str, components: [{name: str, status: int, command: str}, ...]}
  property var components: ListModel {}
  property var status: LaunchManagerInterface.Status.Unknown

  function getLaunchConfigs(server_name, result_callback) {
    if (!server_name || !result_callback) return
    const client = d.getLaunchConfigServiceClient(server_name)
    client.sendRequestAsync({}, function(response) {
      if (!response) {
        Ros2.error("Failed to get launch configs for server " + server_name + ": service call failed")
        result_callback([])
        return
      }
      let launch_configs = response.launch_configs || []
      if (launch_configs.toArray) {
        launch_configs = launch_configs.toArray()
      }
      if (!Array.isArray(launch_configs)) {
        Ros2.warn("Received non-array launch configs for server " + server_name + ": " + launch_configs)
        launch_configs = []
      }
      result_callback(launch_configs)
    })
  }
  
  function loadLaunchConfig(host, config, callback) {
    if (!host || !config) return
    const client = d.getLoadLaunchConfigClient(host)
    if (d.loading && d.loading_started > Date.now() - 5000) {
      Ros2.warn("Already loading a launch config, ignoring request for " + config + " on host " + host)
      return
    }
    d.loading = true
    d.loading_started = Date.now()
    root.status = LaunchManagerInterface.Status.Loading
    client.sendGoalAsync({config: config}, {
      onGoalResponse(goal) {
        if (goal) return
        d.loading = false
        root.status = LaunchManagerInterface.Status.Error
        Ros2.error("Launch goal for config " + config + " on host " + host + " was rejected.")
      },
      onResult(result) {
        d.loading = false
        if (result && result.code === ActionGoalStatus.Succeeded) {
          root.status = LaunchManagerInterface.Status.Active
          Ros2.info("Successfully loaded launch config " + config + " on host " + host)
        } else {
          Ros2.error("Failed to load launch config " + config + " on host " + host + ": " + JSON.stringify(result))
        }
        if (callback) callback(result)
      }
    })
  }

  Subscription {
    topic: root.namespace && root.name && root.namespace + "/" + root.name + "_status" || ""
    onNewMessage: function(message) {
      // Add host if new
      let found = false
      for (let i = 0; i < root.hosts.count; ++i) {
        if (root.hosts.get(i).name == message.name) {
          found = true
          break
        }
      }
      if (!found) {
        root.hosts.append({name: message.name})
        d.registerHost(message.name)
      }
      updateComponents(message)
      if (d.loading) {
        // Ignore status updates while loading, but recover if the goal never delivered a result
        if (d.loading_started > Date.now() - 15000) return
        d.loading = false
        root.status = LaunchManagerInterface.Status.Error
      }
      d.current_launch_config = message.launch_config || ""
      let launch_config = d.getLaunchConfigName(message.name, message.launch_config || "")
      if ((launch_config == "None" || launch_config == "[custom]") && d.lastConfigUpdate > Date.now() - 5000) {
        return // Favor named launch configs for a while
      }
      d.lastConfigUpdate = Date.now()
      if (launch_config == root.config) return // No change in launch config
      root.config = launch_config
    }

    function updateComponents(message) {
      if (!message) return
    
      // for (let i = 0; i < message.component_statuses.length; ++i) {
      //   let compStatus = message.component_statuses.at(i)
      //   newComponents.push({
      //     name: compStatus.name,
      //     status: compStatus.status,
      //     command: compStatus.command
      //   })
      // }
      let found = false
      for (let i = 0; i < root.components.count; i++) {
        let entry = root.components.get(i)
        if (entry.host != message.name) continue
        found = true
        // Update existing and remove old components not contained anymore
        for (let j = 0; j < entry.components.count; ++j) {
          let exists = false
          for (let k = 0; k < message.component_statuses.length; ++k) {
            let compStatus = message.component_statuses.at(k)
            if (compStatus.name != entry.components.get(j).name) continue
            exists = true
            if (entry.components.get(j).status != compStatus.status)
              entry.components.setProperty(j, "status", compStatus.status)
            if (entry.components.get(j).command != compStatus.command)
              entry.components.setProperty(j, "command", compStatus.command)
            break
          }
          if (!exists) {
            entry.components.remove(j, 1)
            j--
          }
        }
        // Add new components
        for (let j = 0; j < message.component_statuses.length; ++j) {
          let compStatus = message.component_statuses.at(j)
          let exists = false
          for (let k = 0; k < entry.components.count; ++k) {
            if (compStatus.name == entry.components.get(k).name) {
              exists = true
              break
            }
          }
          if (!exists) {
            entry.components.append({
              name: compStatus.name,
              status: compStatus.status,
              command: compStatus.command
            })
          }
        }
        entry.lastUpdate = Date.now()
      }

      if (!found) {
        root.components.append({
          host: message.name,
          components: message.component_statuses.toArray(),
          lastUpdate: Date.now()
        })
      }
    }
  }

  QtObject {
    id: d
    property var currentAction: null
    property real lastConfigUpdate: 0
    property string current_launch_config: ""
    property var load_config_action_clients: []
    property var launch_config_service_clients: []
    property bool loading: false
    property real loading_started: 0

    function getLaunchConfigName(host, launch_config) {
      if (!launch_config || launch_config.length == 0) return "None"
      if (host == launch_config || launch_config.length > 32) return "[custom]"
      return launch_config
    }

    function getLaunchConfigServiceClient(host) {
      for (let client of launch_config_service_clients) {
        if (client.host == host) return client.client
      }
      let client = Ros2.createServiceClient(
        root.namespace + "/" + root.name + "/" + HectorRosUtils.sanitizeTopic(host) + "/get_launch_configs",
        "hector_launch_manager_msgs/srv/GetLaunchConfigs"
      )
      launch_config_service_clients.push({host: host, client: client})
      return client
    }

    function getLoadLaunchConfigClient(host) {
      for (let client of load_config_action_clients) {
        if (client.host == host) return client.client
      }
      Ros2.debug("Creating client at: " + root.namespace + "/"  + root.name + "/" + HectorRosUtils.sanitizeTopic(host) + "/launch")
      let client = Ros2.createActionClient(
        root.namespace + "/" + root.name + "/" + HectorRosUtils.sanitizeTopic(host) + "/launch",
        "hector_launch_manager_msgs/action/Launch"
      )
      load_config_action_clients.push({host: host, client: client})
      return client
    }

    function registerHost(host) {
      // Initialize action client
      Ros2.debug("Registering host: " + host)
      d.getLoadLaunchConfigClient(host)
    }
  }
}