ruleset wovyn_base {
    meta {

    }
    global {
        content = ""
    }
  
    rule process_heartbeat {
      select when wovyn heartbeat where event:attrs{"genericcThing"}
      pre {
        content = event:attrs.klog("attrs")
      }
      send_directive(content)
    }
  }