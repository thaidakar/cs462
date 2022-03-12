ruleset new_ruleset_installed {
    meta {
      use module io.picolabs.subscription alias subs
      use module io.picolabs.wrangler alias wrangler
    }

    global {

    }

    rule pico_created {
        select when wrangler ruleset_installed
          where event:attrs{"rids"} >< meta:rid
        pre {
          sensor_id = event:attrs{"sensor_id"}
          parent_eci = event:attrs{"parent_eci"}
        }
        always {
          ent:sensor_id := sensor_id.klog("sensor_id")
          ent:parent_eci := parent_eci.klog("parent_eci")
        }
    }

    rule generate_report {
      select when report generate_report
      pre {
        correlation_id = event:attrs{"correlation_id"}.klog("correlation_id...")
        response_channel = event:attrs{"response_channel"}.klog("response_channel...")
        identifier_channel = event:attrs{"identifier_channel"}.klog("identifier_channel...")
      }
        always {
          raise sensor event "current_temp" attributes {
            "response_channel" : response_channel,
            "correlation_id" : correlation_id,
            "identifier_channel" : identifier_channel
          }
        }
    }

    rule send_report {
      select when report notify_temperature
      pre {
        response_channel = event:attrs{"response_channel"}
        correlation_id = event:attrs{"correlation_id"}
        temperature = event:attrs{"current_temp"}
        identifier_channel = event:attrs{"identifier_channel"}
      }
      event:send(
        {
            "eci" : response_channel,
            "eid" : "report_response",
            "domain" : "report", "type": "report_response",
            "attrs" : {
                "correlation_id" : correlation_id,
                "temperature" : temperature,
                "identifier_channel" : identifier_channel
            }
        })
    }

    rule detect_high_temps {
      select when wovyn threshold_violation
      foreach subs:established() setting (connection)
      pre {
        temperature = event:attrs{"temperature"}
        timestamp = event:attrs{"timestamp"}
      }
      event:send({
        "eci": connection{"Tx"},
        "eid": "violation",
        "domain": "manager", "type": "send_threshold_notification",
        "attrs": {
          "message": temperature + " is too hot! (Recorded from Sensor " + ent:sensor_id + " at " + timestamp + ")"
        }
      })
    }

    rule detect_wovyn_base_installed {
        select when wrangler ruleset_installed
          where event:attrs{"rids"} >< "wovyn_base"
        
          event:send(
            { 
                "eci" : ent:parent_eci,
                "eid" : "installer_complete",
                "domain" : "installer", "type" : "complete",
                "attrs" : {
                    "rule": "wovyn_base",
                    "sensor_id": ent:sensor_id,
                    "wellKnown_Tx": subs:wellKnown_Rx(){"id"},
                    "config" : {}
                }
            }
        )
    }

    rule detect_emitter_installed {
        select when wrangler ruleset_installed
          where event:attrs{"rids"} >< "io.picolabs.wovyn.emitter"
        
          event:send(
            { 
                "eci" : ent:parent_eci,
                "eid" : "installer_complete",
                "domain" : "installer", "type" : "complete",
                "attrs" : {
                    "rule": "io.picolabs.wovyn.emitter",
                    "sensor_id": ent:sensor_id,
                    "wellKnown_Tx": subs:wellKnown_Rx(){"id"},
                    "config" : {}
                }
            }
          )
    }

    rule detect_temperature_store_installed {
        select when wrangler ruleset_installed
          where event:attrs{"rids"} >< "temperature_store"
        
          event:send(
            { 
                "eci" : ent:parent_eci,
                "eid" : "installer_complete",
                "domain" : "installer", "type" : "complete",
                "attrs" : {
                    "rule": "temperature_store",
                    "sensor_id": ent:sensor_id,
                    "wellKnown_Tx": subs:wellKnown_Rx(){"id"},
                    "config" : {}
                }
            }
          )
    }

    rule detect_sensor_profile_installed {
        select when wrangler ruleset_installed
          where event:attrs{"rids"} >< "profile_ruleset"
        
          event:send(
            { 
                "eci" : ent:parent_eci,
                "eid" : "installer_complete",
                "domain" : "installer", "type" : "complete",
                "attrs" : {
                    "rule": "profile_ruleset",
                    "sensor_id":ent:sensor_id,
                    "wellKnown_Tx": subs:wellKnown_Rx(){"id"},
                    "config" : {}
                }
            }
          )
    }
}