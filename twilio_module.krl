ruleset org.thaidakar.twilio {
    meta {
      name "Modules and External APIs Lesson"
      description <<
My sad attempt at the twilio lab
      >> 
      
      provides sendMessage, getMessages

      configure using
        accountSid = ""
        authToken = ""
    }

    global {
      base_url = "https://api.twilio.com/2010-04-01/Accounts/";

      sendMessage = defaction(to, body) {
        authjson = {"username":accountSid, "password":authToken}
        bodyjson = {"Body": body, "From":"+18323491263", "To":to}
        http:post(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson, qs=bodyjson) setting(response)
        return response
      }
      getMessages = defaction() {
        authjson = {"username":accountSid, "password":authToken}
        http:get(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson)  setting(response)
        return response
      }
    }
  }