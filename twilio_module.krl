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

      sendMessage = defaction(toNum, fromNum, body) {
        authjson = {"username":accountSid, "password":authToken}
        bodyjson = {"Body": body, "From":fromNum, "To":toNum}
        http:post(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson, form=bodyjson) setting(response)
        return response
      }
      getMessages = defaction(toNum, fromNum, pageSize) {
        authjson = {"username":accountSid, "password":authToken}
        bodyjson = {"To":toNum, "From":fromNum, "PageSize":pageSize}
        http:get(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson, qs=bodyjson)  setting(response)
        return response 
      }
    }
  }