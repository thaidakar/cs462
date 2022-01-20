ruleset wovyn_base {
    meta {

    }
    global {
        content = ""
    }
  
    rule process_heartbeat {
      select when wovyn heartbeat where event:attrs{"genericThing"}
      pre {
        content = event:attrs.klog("attrs")
        genericThing = event:attrs{"genericThing"}
        data = genericThing{"data"}.decode()
        temperature = data{"temperature"}.decode()
      }
      send_directive(content)
      fired {
          raise wovyn event "new_temperature_reading" attributes {
            "temperature" : temperature,
            "timestamp" : time:now()
          }
      }
    }
  }