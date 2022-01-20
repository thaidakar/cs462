ruleset wovyn_base {
    meta {
    }
    global {
        temperature_threshold = 75
    }
  
    rule process_heartbeat {
      select when wovyn heartbeat
      pre {
        content = event:attrs.klog("attrs")
        genericThing = event:attrs{"genericThing"}
        data = genericThing{"data"}.decode()
        temperature = data{"temperature"}.decode()
      }
      fired {
          raise wovyn event "new_temperature_reading" attributes {
            "temperature" : temperature,
            "timestamp" : time:now()
          } if genericThing != null
      }
    }

    rule find_high_temps {
        select when wovyn new_temperature_reading
        pre {
            content = event:attrs.klog("attrs")
            temperature = event:attrs{"temperature"}
            timestamp = event:attrs{"timestamp"}
            degrees = temperature[0]{"temperatureF"}.decode()
            voilation = degrees > temperature_threshold
        }
        send_directive(degrees + " / " + temperature_threshold + " recorded at " + timestamp)
        fired {
            raise wovyn event "threshold_violation" attributes {
                "degrees":degrees,
            } if voilation
        }
    }

    rule threshold_notification {
        select when wovyn threshold_violation
        pre {
            content = event:attrs.klog("attrs")
            degrees = event:attrs{"degrees"}
            message = "Temperature: " + degrees + " is too hot! (over " + temperature_threshold + ")" 
        }
        fired {
            raise twilio event "send_message" attributes {
                "message":message,
            }
        }
    }
  }