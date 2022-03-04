ruleset manage_sensors {
    meta {
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subs

        shares getSensors, get_temps, get_profiles
    }

    global {
        getSensors = function() {
            ent:sensors
        }

        get_temps = function() {
            subs:established().filter(sensors_only).map(function(data) {
                x = data.klog("data: ")
                wrangler:picoQuery(data{"Tx"},"temperature_store","temperatures")
            })
        }

        sensors_only = function(established) {
            established{"Rx_role"} == "sensor"
        }

        get_profiles = function() {
            ent:sensors.map(function(data, sensor_id) {
                wrangler:picoQuery(data{"eci"}, "profile_ruleset", "get_profile");
            })
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
            wellKnown_Tx = event:attrs{"wellKnown_Tx"}
        }
        always {
            ent:complete{sensor_id} := ent:complete{sensor_id}.defaultsTo([]).append(rule_name)

            raise sensor event "handle_completed_sensor" attributes {
                "sensor_id": sensor_id,
                "wellKnown_Tx": wellKnown_Tx
            } if ent:complete{sensor_id}.length() == 4
        }
    }

    rule handle_completed_sensor {
        select when sensor handle_completed_sensor
        pre {
            
            sensor_id = event:attrs{"sensor_id"}
            eci = ent:sensors{sensor_id}{"eci"}
            name = ent:sensors{sensor_id}{"name"}
            wellKnown_Tx = event:attrs{"wellKnown_Tx"}
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
        fired {
            raise manager event "subscribe" attributes {
                "sensor_id": sensor_id,
                "wellKnown_Tx": wellKnown_Tx
            }
        }
    }

    rule subscription_ruleset {
        select when manager subscribe
        pre {
            sensor_id = event:attrs{"sensor_id"}
            eci = ent:sensors{sensor_id}{"eci"} || event:attrs{"eci"}
            name = ent:sensors{sensor_id}{"name"} || event:attrs{"name"}
            wellKnown_Tx = event:attrs{"wellKnown_Tx"}
        }
        event:send({
            "eci": wellKnown_Tx,
            "domain": "wrangler", "name":"subscription",
            "attrs": {
                "wellKnown_Tx": subs:wellKnown_Rx(){"id"},
                "Rx_role": "manager", "Tx_role":"sensor",
                "name":name+"-manager", "channel_type": "subscription",
                "sensor_id": sensor_id
            }
        })
        fired {
            ent:sensors{sensor_id} := {"eci": eci,"name": name,"wellKnown_Tx": wellKnown_Tx}
        }
    }

    rule inbound_subscription {
        select when wrangler inbound_pending_subscription_added
        fired {
            raise wrangler event "pending_subscription_approval"
                attributes event:attrs
        }
    }

    rule store_sms {
        select when manager store_sms
        pre {
            sms = event:attrs{"sms"}
        }
        always {
            ent:sms := sms.defaultsTo(ent:sms)
        }
    }

    rule send_threshold_notification {
        select when manager send_threshold_notification
        pre {
            message = event:attrs{"message"}.klog("received...")
        }
        event:send({
            "eci": meta:eci,
            "domain": "twilio", "name":"send_message",
            "attrs": {
                "message": message,
                "toNum": ent:sms
            }
        })
    }

    rule initialize_sensors {
        select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
        fired {
            ent:sensors := ent:sensors.defaultsTo({})
            ent:complete := ent:complete.defaultsTo({})
            ent:default_threshold := ent:default_threshold.defaultsTo(76)
            ent:temperatures := ent:temperatures.defaultsTo({})
            ent:sms := ent:sms.defaultsTo("+18323491263")
        }
    }
  }