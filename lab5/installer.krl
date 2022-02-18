ruleset installer {
    meta {

    }

    rule install_emitter {
        select when installer install_emitter
        pre {
            eci = event:attrs{"eci"}
        }
        if eci.klog("installing emitter...") then event:send(
                { 
                    "eci" : eci,
                    "eid" : "io.picolabs.wovyn.emitter",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/windley/temperature-network/main/io.picolabs.wovyn.emitter.krl",
                        "rid" : "io.picolabs.wovyn.emitter",
                        "config" : {}
                    }
                }
            )
    }

    rule install_wovyn_base {
        select when installer install_wovyn_base
        pre {
            eci = event:attrs{"eci"}
        }
        if eci.klog("installing wovyn_base...") then event:send(
                { 
                    "eci" : eci,
                    "eid" : "wovyn_base",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/thaidakar/cs462/main/lab2/wovyn.endpoint.krl",
                        "rid" : "wovyn_base",
                        "config" : {}
                    }
                }
            )
    }

    rule install_temperature_store {
        select when installer install_temperature_store
        pre {
            eci = event:attrs{"eci"}
        }
        if eci.klog("installing temperature_store...") then event:send(
                { 
                    "eci" : eci,
                    "eid" : "temperature_store",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/thaidakar/cs462/main/lab3/temperature_store.krl",
                        "rid" : "temperature_store",
                        "config" : {}
                    }
                }
            )
    }

    rule install_sensor_profile {
        select when installer install_sensor_profile
        pre {
            eci = event:attrs{"eci"}
        }
        if eci.klog("installing sensor_profile...") then event:send(
                { 
                    "eci" : eci,
                    "eid" : "profile_ruleset",
                    "domain" : "wrangler", "type" : "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://github.com/thaidakar/cs462/blob/main/lab4/profile.krl",
                        "rid" : "profile_ruleset",
                        "config" : {}
                    }
                }
            )
    }
}