ruleset gossip_protocol {
    meta {
        use module io.picolabs.subscription alias subs
        
        shares get_seen_messages, get_known_peers
    }

    global {
        parse_sequence_num = function(message) {
            message{"MessageID"}.split(":")[1]
        }

        get_message_id = function() {
            random:uuid()
        }

        get_seen_messages = function() {
            ent:seen_messages
        }

        get_known_peers = function() {
            ent:known_peers
        }
        
        remove_schedule = function(id) {
            schedule:remove(id)
        }

        build_gossip_message = function() {
            {
                "MessageID": get_message_id() + ":" + ent:sequence_num,
                "SensorID": meta:eci,
                "Temperature": ent:temperature,
                "Timestamp": ent:timestamp
            }
        }

        get_peer = function(sensors) {
            sensors.filter(needing_message)[0]
        }

        needing_message = function(sensor) {
            ent:known_peers{sensor{"Tx"}}{meta:eci} < ent:sequence_num
        }

        node_only = function(established) {
            established{"Rx_role"} == "node" && established{"Tx_role"} == "node"
        }
    }

    rule initialize {
        select when debug_gossip initialize
        pre {
            schedule_id = schedule:list()[0]{"id"} || -1
            valid = schedule_id > 0
        }
        always {
            ent:seen_messages := {}
            ent:sequence_num := 0;
            x = remove_schedule(schedule_id) if valid
        }
    }

    rule clear_peer_data {
        select when debug_gossip initialize
        foreach subs:established().filter(node_only) setting (sensor)
        always {
            ent:known_peers{sensor{"Tx"}} := []
        }
    }

    rule add_new_peer {
        select when gossip add_new_peer
        pre {
            tx = event:attrs{"Tx"}
        }
        always {
            ent:known_peers{tx} := []
        }
    }

    // rule send_gossip_message {
    //     select when gossip heartbeat
    //     pre {
    //         subscriber = get_peer(subs:established().filter(node_only)).klog("Subscriber...")
    //         m = build_gossip_message().klog("New gossip message...")
    //     }
    //     event:send({
    //         "eci": subscriber{"Tx"},
    //         "domain": "gossip", "name":"rumor",
    //         "attrs": {
    //             "rumor_message": m
    //         }
    //     })
    //     fired {
    //         ent:sequence_num := ent:sequence_num + 1
    //         ent:known_peers{[subscriber{"Tx"}, meta:eci]} := ent:known_peers{[subscriber{"Tx"}, meta:eci]} + 1;
    //     }
    // }

    // rule new_gossip_message {
    //     select when gossip rumor
    //     pre {
    //         message = event:attrs{"rumor_message"}
    //         sequence_number = parse_sequence_num(message)
    //         sensor_id = message{"SensorID"}
    //         needed = ent:known_peers{sensor_id}.defaultsTo(-1) < sequence_number
    //         next = ent:known_peers{sensor_id}.defaultsTo(-1) + 1 == sequence_number
    //     }
    //     always {
    //         ent:seen_messages{sensor_id} := ent:seen_messages{sensor_id}.defaultsTo([]).append(message) if needed
    //         ent:known_peers{sensor_id} := sequence_number if next
    //     }
    // }

    // rule add_seen_message {
    //     select when gossip seen
    //     pre {
    //         origin_id = event:attrs{"origin_id"}
    //         sequence_number = event:attrs{"sequence_number"}
    //         known_message = ent:seen_messages{origin_id} >< sequence_number
    //     }
    //     always {
    //         ent:seen_messages{origin_id} := sequence_number if not known_message
    //     }
    // }

    // rule set_gossip_period {
    //     select when debug gossip_period
    //     pre {
    //         span = event:attrs{"span"} || 15
    //     }
    //     always {
    //         schedule gossip event "heartbeat" repeat
    //             << */#{span} * * * * * >>
    //     }
    // }

    rule collect_recent_temperature {
        select when wovyn new_temperature_reading
        pre {
            passed_temp = event:attrs{"temperature"}
            passed_timestamp = event:attrs{"timestamp"}
        }
        always {
            ent:timestamp := passed_timestamp
            ent:temperature := passed_temp
        }
    }
}