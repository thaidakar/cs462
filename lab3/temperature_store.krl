ruleset temperature_store {
    meta {
        shares temperatures, threshold_violations, inrange_temperatures
        provides temperatures, threshold_violations, inrange_temperatures
    }

    global {
        clear_temps = { "0": 0 }

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
            temp < 75 && temp > 0
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        always {
            ent:temperatures := clear_temps
            ent:violations := clear_temps
        }
    }

    rule collect_temperatures {
        select when wovyn new_temperature_reading
        pre {
            passed_temp = event:attrs{"temperature"}
            passed_timestamp = event:attrs{"timestamp"}
        }
        send_directive("Storing " + passed_temp + " @ " + passed_timestamp)
        always {
            ent:temperatures{passed_timestamp} := passed_temp
        }
    }

    rule collect_threshold_violations {
        select when wovyn threshold_violation
        pre {
            passed_temp = event:attrs{"temperature"}.klog("passed in temperature: ")
            passed_timestamp = event:attrs{"timestamp"}.klog("passed in timestamp: ")
        }
        send_directive("Storing violation " + passed_temp + " @ " + passed_timestamp)
        always {
            ent:violations{passed_timestamp} := passed_temp
        }
    }
  }