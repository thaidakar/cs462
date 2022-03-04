ruleset wovyn_base {
    meta {
        use module profile_ruleset alias profile
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
      }
    }

    rule find_high_temps {
        select when wovyn new_temperature_reading
        pre {
            content = event:attrs.klog("attrs")
            degrees = event:attrs{"temperature"}
            timestamp = event:attrs{"timestamp"}
            voilation = degrees > profile:threshold()
        }
        send_directive(degrees + " / " +  profile:threshold() + " recorded at " + timestamp)
        fired {
            raise wovyn event "threshold_violation" attributes {
                "temperature" : degrees,
                "timestamp" : timestamp
            } if voilation
        }
    }

    // rule threshold_notification {
    //     select when wovyn threshold_violation
    //     pre {
    //         content = event:attrs.klog("attrs")
    //         temperature = event:attrs{"temperature"}
    //         message = "Temperature: " + temperature + " is too hot! (over " +  profile:threshold() + ")" 
    //     }
    //     send_directive("Sending message...")
    //     fired {
    //         raise twilio event "send_message" attributes {
    //             "message" : message,
    //             "toNum":  profile:sms()
    //         }
    //     }
    // }
  }