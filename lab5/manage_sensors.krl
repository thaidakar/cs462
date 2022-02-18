ruleset manage_sensors {
    meta {
        use module io.picolabs.wrangler alias wrangler

        shares getChildren, getSensors
    }

    global {
        getChildren = function() {
            wrangler:children()
        }

        getSensors = function() {
            ent:sensors
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
                    "name" : "Sensor " + sensor_id + " Pico",
                    "backgroundColor":"#ff69b4",
                    "sensor_id": sensor_id
                }
        }
    }

    rule delete_sensor {
        select when section delete_sensor
        pre {
            sensor_id = event:attrs{"sensor_id"}
            exists = ent:sensors >< sensor_id
            eci_to_delete = ent:sensors{[sensor_id, "eci"]}
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
        }
    }

    rule detect_child_created {
        select when wrangler new_child_created
        pre {
            eci = event:attrs{"eci"}
            the_sensor = { "eci" : eci }
            name = event:attrs{"name"}
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
                    "eid" : "install-ruleset",
                    "domain" : "wrangler", "type": "install_ruleset_request",
                    "attrs" : {
                        "url" : "https://raw.githubusercontent.com/thaidakar/cs462/main/lab5/new_ruleset_added.krl",
                        "rid" : "new_ruleset_installed",
                        "config" : {},
                        "sensor_id" : sensor_id
                    }
                }
            )
    }

    /*
    rule query_rule {
        pre {
            eci = eci_to_other_pico;
            args = {"arg1": val1, "arg2": val2};
            answer = wrangler:picoQuery(eci,"my.ruleset.id","myFunction",{}.put(args));
        }
        if answer{"error"}.isnull() then noop();
        fired {
            // process using answer
        }
    }
     */

    rule initialize_sensors {
        select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
        fired {
            ent:sensors := ent:sensors.defaultsTo({})
        }
    }
  }