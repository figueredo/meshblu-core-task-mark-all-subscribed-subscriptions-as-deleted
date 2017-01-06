{beforeEach, context, describe, it} = global
{expect} = require 'chai'

_                  = require 'lodash'
mongojs            = require 'mongojs'
Datastore          = require 'meshblu-core-datastore'
MarkAllSubscribedSubscriptionsAsDeleted = require '../'

describe 'RemoveSubscription', ->
  beforeEach 'clean the datastore', (done) ->
    database = mongojs 'subscription-manager-test'

    @datastore = new Datastore
      database: database
      collection: 'subscriptions'

    database.subscriptions.remove done

  beforeEach ->
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    @sut = new MarkAllSubscribedSubscriptionsAsDeleted {@datastore, @uuidAliasResolver}

  describe '->do', ->
    context 'when given a valid request', ->
      beforeEach (done) ->
        subscription = {subscriberUuid:'superman', emitterUuid: 'spiderman', type:'broadcast'}
        @datastore.insert subscription, done

      beforeEach (done) ->
        subscription = {subscriberUuid:'spiderman', emitterUuid: 'bonzo', type:'broadcast'}
        @datastore.insert subscription, done

      beforeEach (done) ->
        request =
          metadata:
            responseId: 'its-electric'
            toUuid: 'spiderman'

        @sut.do request, (error, @response) => done error

      it 'should mark the emitterUuid subscription as deleted', (done) ->
        query =
          subscriberUuid: 'superman'
          emitterUuid: 'spiderman'
          type: 'broadcast'

        @datastore.find query, (error, subscriptions) =>
          return done error if error?
          expect(subscriptions).to.have.lengthOf 1
          expect(subscriptions[0]).to.have.property 'deleted', true
          done()

      it 'should mark the subscriberUuid subscription as deleted', (done) ->
        query =
          subscriberUuid: 'spiderman'
          emitterUuid: 'bonzo'
          type: 'broadcast'

        @datastore.find query, (error, subscriptions) =>
          return done error if error?
          expect(subscriptions).to.have.lengthOf 1
          expect(subscriptions[0]).to.have.property 'deleted', true
          done()

      it 'should return a 204', ->
        expectedResponse =
          metadata:
            responseId: 'its-electric'
            code: 204
            status: 'No Content'

        expect(@response).to.deep.equal expectedResponse
