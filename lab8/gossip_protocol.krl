ruleset gossip_protocol {
    meta {
        shares get_peer_logs, get_seen_messages, get_connections, get_scheduled_events, get_power_state, get_total_gossip_violations, get_violation_id, view_violations
    }

    global {
        get_scheduled_events = function() {
            schedule:list()
        }

        get_total_gossip_violations = function() {
            get_total_from_known(ent:stored_counter_ids.values())
        }

        get_violation_id = function() {
            ent:violation_id
        }

        view_violations = function () {
            ent:stored_counter_ids
        }

        get_power_state = function() {
            ent:powered
        }

        get_peer_logs = function() {
            ent:peer_logs
        }

        get_seen_messages = function() {
            ent:stored_messages
        }

        get_connections = function() {
            ent:peer_connections
        }

        get_total_from_known = function(known) {
            known.values().reduce(function(accumulator, curr) {accumulator.defaultsTo(0).klog("accumulator...") + curr.defaultsTo(0).klog("curr...")}).klog("total...");
        }

        parse_message = function(MessageID, part) {
            MessageID.split(":")[part]
        }

        find_missing_versions = function (similar_keys, known_logs, received_logs) {
            similar_keys.filter(function(self) {
                known_logs{self}.difference(received_logs{self}).length() > 0
            })
        }

        find_missing = function(known_logs, received_logs) {
            missing_messages = known_logs.keys().difference(received_logs.keys())
            any_missing_versions = find_missing_versions(known_logs.keys().intersection(received_logs.keys()), known_logs, received_logs)
            missing_messages.union(any_missing_versions)
        }

        get_sensor_id = function(log) {
            log.keys()[0]
        }

        get_needed_messages = function(sensor_id) {
            ent:stored_messages{sensor_id}
        }
    }

    rule handle_seen {
        select when gossip seen
        pre {
            received_logs = event:attrs{"logs"}
            from_id = event:attrs{"from"}
            missing_messages = find_missing(ent:peer_logs{ent:sensor_id}, received_logs)
        }
        always {
            raise gossip event "handle_missing" attributes {
                "messages" : missing_messages,
                "from" : from_id
            } if missing_messages.length() > 0 && ent:powered
        }
    }

    rule handle_counter {
        select when gossip counter
        pre {
            total_in_violation = event:attrs{"total_in_violation"}
            stored_counter_ids = event:attrs{"stored_counter_ids"}
            from_id = event:attrs{"from"}

            not_known = get_total_from_known(ent:stored_counter_ids.values()) != get_total_from_known(stored_counter_ids.values())
            missing = find_missing(ent:stored_counter_ids, stored_counter_ids).klog("missing...")
            missing_counter_value = {}.put(missing, ent:stored_counter_ids{missing}).klog("MISSING VALUES...")
        }
        if not_known && ent:stored_counter_ids >< missing && ent:powered then event:send({
            "eci": get_connections(){[from_id, "Tx"]},
            "domain": "gossip", "name":"handle_missing_counter",
            "attrs": {
                "missing_counter_value": missing_counter_value,
                "from": meta:eci,
                "current_id": ent:violation_id
            }
        })
    }

    rule handle_missing_counter {
        select when gossip handle_missing_counter
        foreach event:attrs{"missing_counter_value"} setting (value)
        pre {
            missing_value = value.klog("missing value...")
            key = missing_value.keys()[0].klog("key...")
            value_value = missing_value.values()[0].klog("value_value...")
        }
        always {
            ent:stored_counter_ids{key} := value_value
        }
    }

    rule handle_missing {
        select when gossip handle_missing 
        pre {
            messages = event:attrs{"messages"}
            sensor_ids = messages
            Messages = sensor_ids.map(get_needed_messages)
            from_id = event:attrs{"from"}
            should_send = messages != null && messages.length() > 0 && messages[0] != null
        }
        if should_send && ent:powered then event:send({
            "eci": get_connections(){[from_id, "Tx"]},
            "domain": "gossip", "name":"rumors",
            "attrs": {
                "Messages": Messages,
            }
        })
    }

    rule send_counter {
        select when gossip send_counter
        pre {
            Peer_ID = event:attrs{"Id"}
            Peer_TX = get_connections(){[Peer_ID, "Tx"]}
        }
        if ent:powered then event:send({
            "eci": Peer_TX,
            "domain": "gossip", "name":"counter",
            "attrs": {
                "total_in_violation": ent:total_in_violation,
                "stored_counter_ids": ent:stored_counter_ids,
                "from": ent:sensor_id
            }
        })
    }
    
    rule send_seen {
        select when gossip send_seen
        pre {
            Peer_ID = event:attrs{"Id"}
            Peer_TX = get_connections(){[Peer_ID, "Tx"]}
            logs_to_send = ent:peer_logs{ent:sensor_id}
        }
        if ent:powered then event:send({
            "eci": Peer_TX,
            "domain": "gossip", "name":"seen",
            "attrs": {
                "logs": logs_to_send,
                "from": ent:sensor_id
            }
        })
    }

    rule handle_rumors {
        select when gossip rumors
        foreach event:attrs{"Messages"} setting (message)
        always {
            raise gossip event "rumorx" attributes {
                "Messages": message
            }
        }
    }

    rule parse_handle_rumors {
        select when gossip rumorx
        foreach event:attrs{"Messages"} setting (message)
        pre {
            sensor_id = message{"SensorID"}
            known = ent:stored_messages{sensor_id}.defaultsTo([]).any(function(entry) {
                entry{"MessageID"} == message{"MessageID"}
            })
        }
        always {
            raise gossip event "rumor" attributes {
                "Message": message
            } if not known
        }
    }

    rule handle_rumor {
        select when gossip rumor 
        pre {
            Message = event:attrs{"Message"}
            message_id_full = Message{"MessageID"}
            message_id = parse_message(message_id_full, 0)
            sequence_num = parse_message(message_id_full, 1)
            sensor_id = Message{"SensorID"}
            next_message_in_sequence = (ent:peer_logs{[sensor_id, sensor_id]}.defaultsTo(-1) + 1) == sequence_num.as("Number")
            known_message = ent:stored_messages{[sensor_id, "MessageID"]} >< message_id_full && (ent:peer_logs{[sensor_id, sensor_id]}.defaultsTo(-1)) >= sequence_num.as("Number")
        }
        always {
            ent:stored_messages{sensor_id} := ent:stored_messages{sensor_id}.defaultsTo([]).append(Message) if not known_message && ent:powered
            ent:peer_logs{[sensor_id, sensor_id]} := (ent:peer_logs{[sensor_id, sensor_id]}.defaultsTo(-1) + 1) if next_message_in_sequence && ent:powered
            ent:peer_logs{[ent:sensor_id, sensor_id]} := (ent:peer_logs{[ent:sensor_id, sensor_id]}.defaultsTo(-1) + 1) if next_message_in_sequence && ent:powered
        }
    }

    rule catch_heartbeat {
        select when gossip heartbeat
        always {
            raise gossip event "create_message" attributes {
                "Id" : get_connections().keys()[0]
            } if ent:powered
        }
    }

    rule handle_heartbeat {
        select when gossip create_message
        pre {
            Peer_ID = event:attrs{"Id"}
            Peer_TX = get_connections(){[Peer_ID, "Tx"]}
            MessageID = ent:sensor_id + ":" + ent:sequence_num
            SensorID = ent:sensor_id
            Temperature = ent:temperature
            Timestamp = ent:timestamp
            Message = {}.put("MessageID", MessageID).put("SensorID", SensorID).put("Temperature", Temperature).put("Timestamp", Timestamp)
        }
        if ent:powered then event:send({
            "eci": Peer_TX,
            "domain": "gossip", "name":"rumor",
            "attrs": {
                "Message": Message
            }
        })
        fired {
            ent:peer_logs{[Peer_ID, ent:sensor_id]} := ent:sequence_num
            ent:peer_logs{[ent:sensor_id, ent:sensor_id]} := ent:sequence_num
            ent:sequence_num := ent:sequence_num + 1
            ent:stored_messages{ent:sensor_id} := ent:stored_messages{ent:sensor_id}.defaultsTo([]).append(Message)
        }
    }

    rule add_peer {
        select when gossip add_peer
        pre {
            ID = event:attrs{"ID"}
            Tx = event:attrs{"Tx"}
        }
        always {
            ent:peer_connections{ID} := {}.put("ID", ID).put("Tx", Tx)
        }
    }

    rule initialize_gossip {
        select when gossip initialize
        foreach ent:peer_connections setting (peer)
        always {
            ent:peer_logs{peer{"ID"}} := {}
        }
    }

    rule nuke_gossip {
        select when gossip nuke
        always {
            ent:peer_logs := {}
            ent:stored_messages := {}
            ent:sequence_num := 0
            ent:total_in_violation := 0
            ent:violation_id := 0
            ent:stored_counter_ids := {}
        }
    }

    rule send_seen_query {
        select when gossip send_seen_query
        foreach get_connections().keys() setting (id)
        always {
            raise gossip event "send_seen" attributes {
                "Id" : id
            } if ent:powered
        }
    }

    rule send_counter_query {
        select when gossip send_counter_query
        foreach get_connections().keys() setting (id)
        always {
            raise gossip event "send_counter" attributes {
                "Id" : id
            } if ent:powered
        }
    }

    rule schedule_gossip {
        select when gossip scheduler
        pre {
            heartbeat_period = event:attrs{"period"} || 10
        }
        always {
            schedule gossip event "heartbeat"
                repeat << */#{heartbeat_period} * * * * * >>
        }
    }

    rule schedule_seen_collection {
        select when gossip schedule_seen
        pre {
            seen_period = event:attrs{"period"} || 15
        }
        always {
            schedule gossip event "send_seen_query"
                repeat << */#{seen_period} * * * * * >>
        }
    }

    rule schedule_counter_collection {
        select when gossip schedule_seen
        pre {
            seen_period = event:attrs{"period"} || 30
        }
        always {
            schedule gossip event "send_counter_query"
                repeat << */#{seen_period} * * * * * >>
        }
    }

    rule toggle_power {
        select when gossip power
        pre {
            message = "Switching power " + ent:powered => "off" | "on";
        }
        send_directive(message)
        always {
            ent:powered := (ent:powered => false | true).klog("Result...")
        }
    }

    rule schedule_cleanup {
        select when gossip schedule_cleanup
        pre {
            id = event:attrs{"id"}
        }
        schedule:remove(id)
    }

    rule collect_recent_temperature {
        select when wovyn new_temperature_reading
        pre {
            passed_temp = event:attrs{"temperature"}
            passed_timestamp = event:attrs{"timestamp"}
            is_in_violation = passed_temp > 75
            violation_id = (is_in_violation => 1 | (ent:violation_id.defaultsTo(0).klog("violation_id was...") == 1 => -1 | 0)).klog("violation id...")
            known = ent:violation_id.defaultsTo(0) == violation_id
            invalid_negative = violation_id < 0 && ent:total_in_violation.defaultsTo(0) == 0
        }
        always {
            ent:timestamp := passed_timestamp
            ent:temperature := passed_temp
            ent:violation_id := known => ent:violation_id.defaultsTo(0) | violation_id
            ent:total_in_violation := known => ent:total_in_violation.defaultsTo(0) | ent:total_in_violation.defaultsTo(0) + (invalid_negative => 0 | ent:violation_id)
            ent:stored_counter_ids{meta:eci} := ent:violation_id
        }
    }

    rule process_heartbeat {
        select when wovyn heartbeat
  
        pre {
          genericThing = event:attrs{"genericThing"}
          data = genericThing{"data"}
          temperature = data{"temperature"}
          degrees = temperature[0]{"temperatureF"}
        }
  
        fired {        
          raise wovyn event "new_temperature_reading" attributes {
              "temperature" : degrees,
              "timestamp" : time:now()
          } if genericThing != null
        }
      }
  

    rule initialize_sensors {
        select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
        fired {
            ent:sensor_id := meta:eci
            ent:sequence_num := 0
            ent:powered := true
            raise gossip event "schedule_seen"
        }
    }
}

//1
//cl1778cic00cd1sbz9eulb8is id (2)
//cl177f6uq00nh1sbzbgwcbf02 tx

//2
//cl1778ada00bg1sbz2hux0l7p id (1)
//cl177f6uu00nj1sbz0r22dij6 tx

//cl1778e8700dh1sbzah2zgqtv id (3)
//cl177fzsz00ri1sbz8fs3gywf

//3
//cl1778cic00cd1sbz9eulb8is id (2)
//cl177fzsv00rf1sbz7rro90co tx

//cl1778h5f00es1sbzbq9u1dqj id (4)
//cl177grvm00uv1sbz4a8vgwe4 tx

//cl1778ixg00ga1sbz5zb02etf id (5)
//cl177h77600wf1sbz2dtg7k4q tx

//4
//cl1778e8700dh1sbzah2zgqtv id (3)
//cl177grvi00ut1sbzh8xg4wi8

//cl1778ixg00ga1sbz5zb02etf id (5)
//cl177hsk600zu1sbzbnfr95tg tx

//5
//cl1778e8700dh1sbzah2zgqtv id (3)
//cl177h77300wd1sbzcvh482xv tx

//cl1778h5f00es1sbzbq9u1dqj id (4)
//cl177hsk200zr1sbz5a6l53iw tx

//cl18rea6q04gnwubz004s0za3 id (toAdd)
//cl18rf4ca04kjwubz9b6i60fb tx

//To add
//cl1778ixg00ga1sbz5zb02etf id (5)
//cl18rf4c604kgwubz0kj02qda tx