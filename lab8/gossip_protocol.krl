ruleset gossip_protocol {
    meta {
        use module io.picolabs.subscription alias subs
    }

    global {
        get_unique_message_id = function() {
            random:uuid()
        }
    }

    rule reset_gossip {
        select when gossip reset
        foreach subs:established() setting (peer)
        always {
            ent:peer_logs{peer{"Tx"}} := []
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
}