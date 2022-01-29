ruleset wovyn_base {
    meta {
        shares temperatures
    }
    global {
        temperature_threshold = 75

        clear_temps = { "temperature": 0, "timestamp": 0 }

        temperatures = function() {
            ent:temperatures
        }

        voilations = function() {
            ent:voilations
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        always {
            ent:temperatures := clear_temps
            ent:voilations := clear_temps
        }
    }

    rule store_temperature {
        select when echo store_temperature
        pre {
            passed_temp = event:attrs{"temperature"}.klog("passed in temperature: ")
            passed_timestamp = event:attrs{"timestamp"}.klog("passed in timestamp: ")
        }
        always {
            // ent:temperatures := ent:temperatures.defaultsTo(clear_temps, "initialization was needed")
            ent:temperatures{passed_timestamp} := passed_temp
        }
    }

    rule store_violation {
        select when echo store_violation
        pre {
            passed_temp = event:attrs{"temperature"}.klog("passed in temperature: ")
            passed_timestamp = event:attrs{"timestamp"}.klog("passed in timestamp: ")
        }
        always {
            // ent:violations := ent:violations.defaultsTo(clear_temps, "initialization was needed")
            ent:violations{passed_timestamp} := passed_temp
        }
    }
  
    rule process_heartbeat {
      select when wovyn heartbeat
      pre {
        content = event:attrs.klog("attrs")
        genericThing = event:attrs{"genericThing"}
        data = genericThing{"data"}
        temperature = data{"temperature"}
        degrees = temperature[0]{"temperatureF"}
      }
      fired {
          raise wovyn event "new_temperature_reading" attributes {
            "temperatureF" : degrees,
            "timestamp" : time:now()
          } if genericThing != null
      }
    }

    rule find_high_temps {
        select when wovyn new_temperature_reading
        pre {
            content = event:attrs.klog("attrs")
            degrees = event:attrs{"temperatureF"}
            timestamp = event:attrs{"timestamp"}
            voilation = degrees > temperature_threshold
        }
        send_directive(degrees + " / " + temperature_threshold + " recorded at " + timestamp)
        fired {
            raise wovyn event "threshold_violation" attributes {
                "degrees":degrees,
            } if voilation

            raise echo event "store_violation" attributes {
                "temperature":degrees,
                "timestamp":timestamp
            } if voilation
        }
    }

    rule temperature_store {
        select when wovyn new_temperature_reading
        pre {
            degrees = event:attrs{"temperatureF"}
            timestamp = event:attrs{"timestamp"}
        }
        send_directive("Storing " + degrees + " @ " + timestamp)
        always {
            raise echo event "store_temperature" attributes {
                "temperature": degrees,
                "timestamp": timestamp
            }
        }
    }

    rule threshold_notification {
        select when wovyn threshold_violation
        pre {
            content = event:attrs.klog("attrs")
            degrees = event:attrs{"degrees"}
            message = "Temperature: " + degrees + " is too hot! (over " + temperature_threshold + ")" 
        }
        send_directive("Sending message...")
        fired {
            raise twilio event "send_message" attributes {
                "message":message,
            }
        }
    }
  }