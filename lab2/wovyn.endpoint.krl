ruleset wovyn_base {
    meta {
        provides threshold

        shares get_profile
    }

    global {
        threshold = function() {
            ent:profile{"temperature_threshold"}
        }

        get_profile = function() {
            ent:profile
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
        //initialize if null
        ent:profile{"temperature_threshold"} := ent:profile{"temperature_threshold"} || 75
        ent:profile{"location"} := ent:profile{"location"} || "right here!"
        ent:profile{"name"} := ent:profile{"name"} || "seanethan"
        ent:profile{"sms"} := ent:profile{"sms"} || "+18323491263"
        
        raise wovyn event "new_temperature_reading" attributes {
            "temperature" : degrees,
            "timestamp" : time:now()
        } if genericThing != null
      }
    }

    rule sensor_profile {
        select when sensor profile_updated
        pre {
            content = event:attrs.klog("attrs")
            threshold = event:attrs{"threshold"}
            location = event:attrs{"location"}
            name = event:attrs{"name"}
            sms = event:attrs{"sms"}
        }
        always {
            ent:profile{"temperature_threshold"} := threshold || ent:profile{"temperature_threshold"}
            ent:profile{"location"} := location || ent:profile{"location"}
            ent:profile{"name"} := name || ent:profile{"name"}
            ent:profile{"sms"} := sms || ent:profile{"sms"}
        }
    }

    rule find_high_temps {
        select when wovyn new_temperature_reading
        pre {
            content = event:attrs.klog("attrs")
            degrees = event:attrs{"temperature"}
            timestamp = event:attrs{"timestamp"}
            voilation = degrees > ent:profile{"temperature_threshold"}
        }
        send_directive(degrees + " / " + ent:profile{"temperature_threshold"} + " recorded at " + timestamp)
        fired {
            raise wovyn event "threshold_violation" attributes {
                "temperature" : degrees,
                "timestamp" : timestamp
            } if voilation
        }
    }

    rule threshold_notification {
        select when wovyn threshold_violation
        pre {
            content = event:attrs.klog("attrs")
            temperature = event:attrs{"temperature"}
            message = "Temperature: " + temperature + " is too hot! (over " + ent:profile{"temperature_threshold"} + ")" 
        }
        send_directive("Sending message...")
        fired {
            raise twilio event "send_message" attributes {
                "message" : message,
                "toNum": ent:profile{"sms"}
            }
        }
    }
  }