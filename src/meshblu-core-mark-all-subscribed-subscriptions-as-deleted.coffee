http = require 'http'
SubscriptionManager = require 'meshblu-core-manager-subscription'

class MarkAllSubscribedSubscriptionsAsDeleted
  constructor: ({@datastore,@uuidAliasResolver}) ->
    @subscriptionManager = new SubscriptionManager {@datastore, @uuidAliasResolver}

  _doCallback: (request, code, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
    callback null, response

  do: (request, callback) =>
    {toUuid} = request.metadata

    @subscriptionManager.markAllAsDeleted subscriberUuid: toUuid, (error) =>
      return @_doCallback request, error.code || 500, callback if error
      @subscriptionManager.markAllAsDeleted emitterUuid: toUuid, (error) =>
        return @_doCallback request, error.code || 500, callback if error
        return @_doCallback request, 204, callback

module.exports = MarkAllSubscribedSubscriptionsAsDeleted
