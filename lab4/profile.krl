ruleset profile_ruleset {
    meta {
        provides threshold, sms

        shares get_profile
    }

    global {
        threshold = function() {
            ent:profile{"temperature_threshold"}
        }

        sms = function() {
            ent:profile{"sms"}
        }

        get_profile = function() { 
            ent:profile
        }
    }

    rule initialize_profile {
        select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
        fired {
            ent:profile{"temperature_threshold"} := ent:profile{"temperature_threshold"}.defaultsTo(75)
            ent:profile{"location"} := ent:profile{"location"}.defaultsTo("right here!")
            ent:profile{"name"} := ent:profile{"name"}.defaultsTo("seanethan")
            ent:profile{"sms"} := ent:profile{"sms"}.defaultsTo("+18323491263")
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
  }