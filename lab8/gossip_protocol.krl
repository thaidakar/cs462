ruleset gossip_protocol {
    meta {
        shares get_peer_logs, get_seen_messages, get_connections
    }

    global {
        get_unique_message_id = function() {
            random:uuid()
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

        parse_message = function(MessageID, part) {
            MessageID.split(":")[part]
        }
    }

    rule handle_rumor {
        select when gossip rumor 
        pre {
            Message = event:attrs{"Message"}.klog("Message...")
            message_id_full = Message{"MessageID"}
            message_id = parse_message(message_id_full, 0)
            sequence_num = parse_message(message_id_full, 1)
            sensor_id = Message{"SensorID"}
            next_message_in_sequence = (ent:peer_logs{sensor_id} + 1).klog("peer_logs(sensor_id) + 1 =") == sequence_num.as("Number").klog("sequence_num as number")
            known_message = ent:stored_messages{[sensor_id, "MessageID"]} >< message_id_full
        }
        always {
            ent:stored_messages{sensor_id} := ent:stored_messages{sensor_id}.defaultsTo([]).append(Message) if not known_message
            ent:peer_logs{sensor_id} := sequence_num if next_message_in_sequence
        }
    }

    rule handle_heartbeat {
        select when gossip create_message
        pre {
            Peer = event:attrs{"Tx"}
            MessageID = get_unique_message_id() + ":" + ent:sequence_num
            SensorID = ent:sensor_id
            Temperature = ent:temperature
            Timestamp = ent:timestamp
            Message = {}.put("MessageID", MessageID).put("SensorID", SensorID).put("Temperature", Temperature).put("Timestamp", Timestamp)
        }
        event:send({
            "eci": Peer,
            "domain": "gossip", "name":"rumor",
            "attrs": {
                "Message": Message
            }
        })
        fired {
            ent:sequence_num := ent:sequence_num + 1
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

    rule reset_gossip {
        select when gossip reset
        foreach ent:peer_connections setting (peer)
        always {
            ent:peer_logs{peer{"ID"}} := -1
        }
    }

    rule reset_stored {
        select when gossip reset
        always {
            ent:stored_messages := {}
            ent:sequence_num := 0
        }
    }

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
        }
    }
}