ruleset post_test {
    meta {

    }
    global {
        content = ""
    }
  
    rule post_test {
      select when wovyn heartbeat
      pre {
        content = event:attrs.klog("attrs")
      }
      send_directive(content)
    }

    rule get {
        select when echo content 

        send_directive(content)
    }
  }