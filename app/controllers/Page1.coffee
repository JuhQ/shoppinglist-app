'use strict'
app = angular.module('shoppingListApp')

app.controller 'Page1Ctrl', ($scope, $timeout, Items) ->
  steroids.view.navigationBar.show { title: "Items" }
  $scope.items = []

  $scope.order = '-votes'

  pubnub = PUBNUB.init(
    publish_key: "pub-c-875b3f45-7a42-4cb0-a414-d0d47f340dc9"
    subscribe_key: "sub-c-b4cdb57a-278b-11e4-8eb2-02ee2ddab7fe"
  )


  processItems = (items) ->
    $timeout ->
      $scope.items = items


  loadItems = ->
    Items
      .findAll()
      .then processItems

  loadItems()

  $scope.vote = (item) ->
    item.votes++
    copy = angular.copy(item)
    Items
      .update(item.id, copy)
      .then ->
        item.type = 'vote'
        pubnub.publish
          channel: "kauppakassi"
          message: item

  $scope.remove = (item) ->
    removeConfirm = (buttonIndex) ->
      if buttonIndex is 1
        Items
          .remove(item.id)
          .then ->
            item.type = 'remove'
            pubnub.publish
              channel: "kauppakassi"
              message: item

    navigator.notification.confirm "Are you sure you want to remove this item?", removeConfirm, "Remove item"



  clearAllConfirm = (buttonIndex) ->
    if buttonIndex is 1

      # TODO this behavior is incorrect
      # This should have promises, after all have been removed, send socket call
      # Even better would be to have a flush method in steroids data
      pubnub.publish
        channel: "kauppakassi"
        message: {type: 'clear'}

      _.each $scope.items, (item) ->
        Items.remove(item.id)


  $scope.clearAll = ->
    navigator.notification.confirm "Are you sure you want to empty the list?", clearAllConfirm, "Clear list"

  throttledChangeColor = ->
    pubnub.publish
      channel: "kauppakassi"
      message: {type: 'color', color: $scope.color}

  $scope.changeColor = _.throttle throttledChangeColor, 100



  $scope.saveItem = ->
    if !$scope.item.length
      return

    item =
      votes: 1
      created_at: new Date()
      name: $scope.item
      is_bought: false

    $scope.item = ''

    Items
      .create(item)
      .then (item) ->
        message = item
        message.type = 'new'

        pubnub.publish
          channel: "kauppakassi"
          message: message


  pubnub.subscribe
    channel: "kauppakassi"
    callback: (message) ->
      steroids.logger.log "I got the message", message
      $timeout ->
        if message.type is "new"
          $scope.items.push message

        if message.type is "vote"
          item = _.find $scope.items, {id: message.id}
          item.votes = message.votes

        if message.type is "remove"
          _.remove $scope.items, {id: message.id}

        if message.type is "clear"
          $scope.items = []

        if message.type is "color"
          steroids.view.navigationBar.setAppearance tintColor: message.color

