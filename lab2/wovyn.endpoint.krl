ruleset wovyn_base {
    meta {

    }
    global {
        content = ""
    }
  
    rule process_heartbeat {
      select when wovyn heartbeat
      pre {
        content = event:attrs.klog("attrs")
      }
      send_directive(content)
    }
  }