ruleset org.thaidakar.twillo {
    meta {
      configure using
        accountSid = ""
        authToken = ""

      provides sendMessage, getMessages
    }

    global {
      sendMessage = defaction(body) {
        queryString = {"AccountSid":accountSid, "AuthToken":authToken}
        bodyjson = {"body": body}
        http:post("https://api.twilio.com/2010-04-01/Accounts/" + accountSid + "/Messages.json", auth=queryString, qs=bodyjson) setting(response)
        return response
      }
      getMessages = defaction() {
        queryString = {"username":accountSid, "password":authToken}
        body = {"body": body}
        http:get("https://api.twilio.com/2010-04-01/Accounts/" + accountSid + "/Messages.json", auth=queryString, qs=body) setting(response)
        return response
      }
    }
  }