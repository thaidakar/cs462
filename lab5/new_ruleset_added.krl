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
        // if parent_eci.klog("found parent_eci") then event:send(
        //     {
        //         "eci": parent_eci,
        //         "eid": "installed",
        //         "domain": "installer", "type": "install_sensor_profile",
        //         "attrs": {
        //             "eci": meta:eci
        //         }
        //     }
        // )
        always {
          ent:sensor_id := sensor_id.klog("sensor_id")
          ent:parent_eci := parent_eci.klog("parent_eci")
        }
    }

    // rule profile_installed {
    //     select when wrangler ruleset_installed
    //       where event:attrs{"rids"} >< "profile_ruleset"
    //     if ent:parent_eci.klog("installing temperature_store") then event:send(
    //         {
    //             "eci": ent:parent_eci,
    //             "eid": "installed",
    //             "domain": "installer", "type": "install_temperature_store",
    //             "attrs": {
    //                 "eci": meta:eci
    //             }
    //         }
    //     )
    //     always {
    //       ent:sensor_id := sensor_id
    //     }
    // }

    // rule temperature_store_installed {
    //     select when wrangler ruleset_installed
    //       where event:attrs{"rids"} >< "temperature_store"
    //     if ent:parent_eci.klog("installing temperature_store") then event:send(
    //         {
    //             "eci": ent:parent_eci,
    //             "eid": "installed",
    //             "domain": "installer", "type": "install_temperature_store",
    //             "attrs": {
    //                 "eci": meta:eci
    //             }
    //         }
    //     )
    //     always {
    //       ent:sensor_id := sensor_id
    //     }
    // }
}