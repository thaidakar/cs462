ruleset twilio {
    meta {
      shares lastResponse
      use module org.thaidakar.twilio alias twilio_api
        with
          accountSid = meta:rulesetConfig{"account_sid"}
          authToken = meta:rulesetConfig{"auth_token"}
    }

    global {
        lastResponse = function() {
        {}.put(ent:lastTimestamp,ent:lastResponse)
      }
    }

    rule send_message {
        select when twilio send
        pre {
            body = event:attrs{"body"} || "";
            to = event:attrs{"to"} || "+18323491263"
        }
        twilio_api:sendMessage(to, body) setting(response)
        fired {
            ent:lastResponse := response
            ent:lastTimestanp := time:now()
        }
    }

    rule get_messages {
        select when twilio get
        twilio_api:getMessages() setting(response)
        fired {
            ent:lastResponse := response
            ent:lastTimestanp := time:now()
        }
    }
    
  }