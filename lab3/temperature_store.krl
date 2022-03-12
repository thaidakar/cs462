ruleset temperature_store {
    meta {
        shares temperatures, threshold_violations, inrange_temperatures
        provides temperatures, threshold_violations, inrange_temperatures

        use module profile_ruleset alias profile
    }

    global {
        clear_temps = { }

        temperatures = function() {
            ent:temperatures.klog("temperatures...")
        }

        threshold_violations = function() {
            ent:violations
        }

        inrange_temperatures = function() {
            temperatures(){"temperatures"}.filter(checkViolation)
        }

        checkViolation = function(temp) {
            temp{"temperature"} < profile:threshold()
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
            passed_temp = event:attrs{"temperature"}.klog("passed in temperature: ")
            passed_timestamp = event:attrs{"timestamp"}.klog("passed in timestamp: ")
        }
        send_directive("Storing " + passed_temp + " @ " + passed_timestamp)
        always {
            new_entry = {}.put("timestamp", passed_timestamp).put("temperature", passed_temp)
            ent:temperatures{"temperatures"} := ent:temperatures{"temperatures"}.defaultsTo([]).append(new_entry)
            ent:temperatures{"current_temp"} := passed_temp
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
            ent:violations{"violations"} := ent:violations{"violations"}.defaultsTo([]).append(passed_temp)
        }
    }
  }