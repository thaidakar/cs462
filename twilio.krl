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
        select when twilio send_message
        pre {
            body = event:attrs{"message"} || "";
            toNum = event:attrs{"toNum"} || "+18323491263";
            fromNum = event:attrs{"fromNum"} || "+19402837542";
        }
        twilio_api:sendMessage(toNum, fromNum, body) setting(response)
        fired {
            ent:lastResponse := response
            ent:lastTimestanp := time:now()
        }
    }

    rule get_messages {
        select when twilio messages
        pre {
            pageSize = event:attrs{"pageSize"} || "50";
            toNum = event:attrs{"toNum"} || "";
            fromNum = event:attrs{"fromNum"} || "";
        }
        twilio_api:getMessages(toNum, fromNum, pageSize) setting(response)
        fired {
            ent:lastResponse := response
            ent:lastTimestanp := time:now()
        }
    }

    rule page_message {
        select when twilio page_message
        pre {
            uri = event:attrs{"uri"} || ""
        }
        twilio_api:pageMessage(uri) setting (response)
        fired {
            ent:lastResponse := response
            ent:lastTimestanp := time:now()
        }
    }
    
  }