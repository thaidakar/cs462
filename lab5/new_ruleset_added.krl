ruleset new_ruleset_installed {
    meta {
      use module io.picolabs.subscription alias subs
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