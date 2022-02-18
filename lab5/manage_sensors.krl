ruleset manage_sensors {
    meta {
        use module io.picolabs.wrangler alias wrangler

        shares getSensors
    }

    global {
        getSensors = function() {
            ent:sensors
        }

        getTemperatures = function() {
            ent:temperatures
        }
    }

    rule handle_new_sensor {
        select when sensor new_sensor
        pre {
            sensor_id = event:attrs{"sensor_id"}
            exists = ent:sensors && ent:sensors >< sensor_id
        }
        if exists then
            send_directive("Sensor_ready", { "sensor_id" : sensor_id })
        notfired {
            raise wrangler event "new_child_request"
                attributes {
                    "name" : "Sensor " + sensor_id,
                    "backgroundColor":"#ff69b4",
                    "sensor_id": sensor_id
                }
        }
    }

    rule delete_sensor {
        select when sensor unneeded_sensor
        pre {
            sensor_id = event:attrs{"sensor_id"}
            exists = ent:sensors >< sensor_id
            eci_to_delete = ent:sensors{sensor_id}{"eci"}
        }

        if exists && eci_to_delete then
            send_directive("deleting_sensor", {"sensor_id":sensor_id})

        fired {
            raise wrangler event "child_deletion_request"
                attributes { "eci" : eci_to_delete }

            clear ent:sensors{sensor_id}
        }
    }

    rule clear_sensor_data {
        select when sensor clear_data
        fired {
            ent:sensors := {}
            ent:complete := {}
            ent:temperatures := {}
        }
    }

    rule detect_child_created {
        select when wrangler new_child_created
        pre {
            eci = event:attrs{"eci"}
            name = event:attrs{"name"}
            the_sensor = { "eci" : eci, "name": name }
            sensor_id = event:attrs{"sensor_id"}
        }
        fired {
            ent:sensors{sensor_id} := the_sensor
        }
    }

    rule install_rulesets {
        select when wrangler new_child_created
        pre {
            eci = event:attrs{"eci"}
            name = event:attrs{"name"}
            sensor_id = event:attrs{"sensor_id"}
        }
        
        if sensor_id.klog("found sensor_id")
            then event:send(
                {
                    "eci" : eci,
                    "eid" : "install_ruleset",
                    "domain" : "wrangler", "type": "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/thaidakar/cs462/main/lab5/new_ruleset_added.krl",
                        "rid" : "new_ruleset_installed",
                        "config" : {},
                        "sensor_id" : sensor_id,
                        "parent_eci" : meta:eci
                    }
                }
            )
        
        fired {
            raise installer event "install_emitter" attributes {
                "eci": eci
            } if sensor_id

            raise installer event "install_sensor_profile" attributes {
                "eci": eci
            } if sensor_id

            raise installer event "install_temperature_store" attributes {
                "eci": eci
            } if sensor_id

            raise installer event "install_wovyn_base" attributes {
                "eci": eci
            } if sensor_id
        }
    }

    rule installer_complete {
        select when installer complete
        pre {
            rule_name = event:attrs{"rule"}
            sensor_id = event:attrs{"sensor_id"}
        }
        always {
            ent:complete{sensor_id} := ent:complete{sensor_id}.defaultsTo([]).append(rule_name)

            raise sensor event "handle_completed_sensor" attributes {
                "sensor_id": sensor_id
            } if ent:complete{sensor_id}.length() == 4
        }
    }

    rule handle_completed_sensor {
        select when sensor handle_completed_sensor
        pre {
            
            sensor_id = event:attrs{"sensor_id"}
            eci = ent:sensors{sensor_id}{"eci"}
            name = ent:sensors{sensor_id}{"name"}
        }
        if eci && name && sensor_id then event:send(
            {
                "eci" : eci,
                "eid" : "profile_updated",
                "domain" : "sensor", "type": "profile_updated",
                "attrs" : {
                    "config" : {},
                    "sensor_id" : sensor_id,
                    "parent_eci" : meta:eci,
                    "name" : name,
                    "threshold" : ent:default_threshold
                }
            }
        )
    }

    rule query_sensors {
        select when sensor query
        pre {
            hm = {}
            results = ent:sensors.map(function(data, sensor_id) {
                return hm{sensor_id}.put(wrangler:picoQuery(data{"eci"},"temperature_store","temperatures"))
            })
        }
        send_directive(results, hm)
    }


    rule initialize_sensors {
        select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
        fired {
            ent:sensors := ent:sensors.defaultsTo({})
            ent:complete := ent:complete.defaultsTo({})
            ent:default_threshold := ent:default_threshold.defaultsTo(76)
            ent:temperatures := ent:temperatures.defaultsTo({})
        }
    }
  }