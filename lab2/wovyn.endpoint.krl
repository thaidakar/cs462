ruleset post_test {
    meta {
      shares __testing
    }
    global {
      __testing = { "queries": [ { "name": "__testing" } ],
                    "events": [ { "domain": "post", "type": "test",
                                "attrs": [ "temp", "baro" ] } ] }
    }
  
    rule post_test {
      select when wovyn heartbeat
      pre {
        never_used = event:attrs.klog("attrs")
      }
    }
  }