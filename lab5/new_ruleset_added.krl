ruleset new_ruleset_installed {
    meta {

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

          raise installer event "install_sensor_profile"
        }
    }

    rule install_emitter {
        select when installer install_emitter
        if meta:eci.klog("installing emitter...") then event:send(
                { 
                    "eci" : meta:eci,
                    "eid" : "io.picolabs.wovyn.emitter",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/windley/temperature-network/main/io.picolabs.wovyn.emitter.krl",
                        "config" : {}
                    }
                }
            )
    }

    rule install_wovyn_base {
        select when installer install_wovyn_base
        if meta:eci.klog("installing wovyn_base...") then event:send(
                { 
                    "eci" : meta:eci,
                    "eid" : "wovyn_base",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/thaidakar/cs462/main/lab2/wovyn.endpoint.krl",
                        "config" : {}
                    }
                }
            )
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
                    "config" : {}
                }
            }
        )
    }

    rule install_temperature_store {
        select when installer install_temperature_store
        if meta:eci.klog("installing temperature_store...") then event:send(
                { 
                    "eci" : meta:eci,
                    "eid" : "temperature_store",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/thaidakar/cs462/main/lab3/temperature_store.krl",
                        "config" : {}
                    }
                }
            )
    }

    rule detect_temperature_store_installed {
        select when wrangler ruleset_installed
          where event:attrs{"rids"} >< "temperature_store"
        
        always {
            raise installer event "install_wovyn_base"
        }
    }

    rule install_sensor_profile {
        select when installer install_sensor_profile
        if meta:eci.klog("installing sensor_profile...") then event:send(
                { 
                    "eci" : meta:eci,
                    "eid" : "profile_ruleset",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/thaidakar/cs462/main/lab4/profile.krl",
                        "config" : {}
                    }
                }
            )
    }

    rule detect_sensor_profile_installed {
        select when wrangler ruleset_installed
          where event:attrs{"rids"} >< "profile_ruleset"
        
        always {
            raise installer event "install_temperature_store"
        }
    }
}