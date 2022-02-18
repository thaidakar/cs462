ruleset new_ruleset_installed {
    meta {

    }

    rule pico_created {
        select when wrangler ruleset_installed
          where event:attr("rids") >< meta:rid
        pre {
          sensor_id = event:attr("sensor_id")
        }
        always {
          ent:sensor_id := sensor_id
        }
    }

    rule install_emitter {
        select when wrangler ruleset_installed
            where event:attr("rids") >< "new_ruleset_installed"
        
        event:send(
            { 
                "eci" : meta:eci,
                "eid" : "io.picolabs.wovyn.emitter",
                "domain" : "wrangler", "type" : "install_ruleset_request",
                "attrs" : {
                    "url" : "",
                    "rid" : "io.picolabs.wovyn.emitter",
                    "config" : {}
                }
            }
        )
    }
}