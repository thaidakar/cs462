ruleset org.thaidakar.twilio {
    meta {
      name "Modules and External APIs Lesson"
      description <<
My sad attempt at the twilio lab
      >> 
      
      provides sendMessage, getMessages, pageMessage

      configure using
        accountSid = ""
        authToken = ""
    }

    global {
      base_url = "https://api.twilio.com/2010-04-01/Accounts/";
      authjson = {"username":accountSid, "password":authToken};

      sendMessage = defaction(toNum, fromNum, body) {
        bodyjson = {"Body": body, "From":fromNum, "To":toNum}
        http:post(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson, form=bodyjson) setting(response)
        return response
      }
      getMessages = defaction(toNum, fromNum, pageSize) {
        bodyjson = {"To":toNum, "From":fromNum, "PageSize":pageSize}
        http:get(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson, qs=bodyjson) setting(response)
        return response 
      }
      pageMessage = defaction(uri) {
        http:get(<<https://api.twilio.com#{uri}>>, auth=authjson) setting(response)
        return response
      }
    }
  }