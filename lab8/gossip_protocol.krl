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

        parse_sequence_num = function(MessageID) {
            MessageID.split(":")[1]
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
            ent:peer_logs{peer{"ID"}} := {}
        }
    }

    rule reset_stored {
        select when gossip reset
        always {
            ent:stored_messages := {}
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

    rule initialize_sensors {
        select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
        fired {
            ent:sensor_id := meta:eci
        }
    }
}