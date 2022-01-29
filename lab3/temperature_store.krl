ruleset temperature_store {
    meta {
        shares temperatures, threshold_violations, inrange_temperatures
        provides temperatures, threshold_violations, inrange_temperatures
    }

    global {
        clear_temps = { "temperature": 0, "timestamp": 0 }

        temperatures = function() {
            ent:temperatures
        }

        threshold_violations = function() {
            ent:violations
        }

        inrange_temperatures = function() {
            temperatures().filter(checkViolation)
        }

        checkViolation = function(temp) {
            temp > 75
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        always {
            ent:temperatures := clear_temps
            ent:violations := clear_temps
        }
    }

    rule store_temperature {
        select when echo store_temperature
        pre {
            passed_temp = event:attrs{"temperature"}.klog("passed in temperature: ")
            passed_timestamp = event:attrs{"timestamp"}.klog("passed in timestamp: ")
        }
        send_directive("Storing " + passed_temp + " @ " + passed_timestamp)
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
        send_directive("Storing violation " + passed_temp + " @ " + passed_timestamp)
        always {
            // ent:violations := ent:violations.defaultsTo(clear_temps, "initialization was needed")
            ent:violations{passed_timestamp} := passed_temp
        }
    }

    rule temperature_store {
        select when wovyn new_temperature_reading
        pre {
            degrees = event:attrs{"temperatureF"}
            timestamp = event:attrs{"timestamp"}
        }
        always {
            raise echo event "store_temperature" attributes {
                "temperature": degrees,
                "timestamp": timestamp
            }
        }
    }
  }