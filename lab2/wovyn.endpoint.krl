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
          raise wovyn event "new_temperature_reading" attributes {
            "temperature" : degrees,
            "timestamp" : time:now()
          } if genericThing != null

          ent:profile{"temperature_threshold"} := ent:profile{"temperature_threshold"} || 75
      }
    }

    rule sensor_profile {
        select when sensor profile_updated
        pre {
            threshold = event:attrs{"threshold"} || 75
            location = event:attrs{"location"} || "right here"
            name = event:attrs{"name"} || "seanethan"
            sms = event:attrs{"sms"} || "8323491263"
        }
        always {
            ent:profile{"temperature_threshold"} := threshold
            ent:profile{"location"} := location
            ent:profile{"name"} := name
            ent:profile{"sms"} := sms
        }
    }

    rule update_threshold {
        select when update threshold
        pre {
            threshold = event:attrs{"threshold"} || 75
        }
        always {
            ent:profile{"temperature_threshold"} := threshold
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
                "toNum": ent:profile{"sms"} || ("+18323491263")
            }
        }
    }
  }