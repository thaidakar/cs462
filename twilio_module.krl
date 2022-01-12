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

      sendMessage = function(body) {
        authjson = {"AccountSid":accountSid, "AuthToken":authToken}
        bodyjson = {"body": body}
        return http:post(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson, qs=bodyjson){"content"}.decode()
      }
      getMessages = function() {
        authjson = {"username":accountSid, "password":authToken}
        return http:get(<<#{base_url}#{accountSid}/Messages.json>>, auth=authjson){"content"}.decode()
      }
    }
  }