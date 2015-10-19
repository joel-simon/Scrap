cache = {}
loadElements = (spacekey, callback) ->
  return callback cache[spacekey] if cache[spacekey]
  $.get "/collectionContent/#{spacekey}", (data) ->
    console.log "got collection from #{spacekey}"
    cache[spacekey] = $(data)
    callback cache[spacekey]

coverToCollection = (cover, elements) ->
  spacekey = cover.data('content').spaceKey
  collection = $("<div>").
    addClass("collection open #{spacekey}").
    data({ spacekey }).
    insertBefore(cover).
    append cover
  
  collectionContent = $("<div>").
    addClass('collectionContent').
    appendTo(collection).
    append elements

  collection

collectionOpen = (cover, options = {}) ->
  return if cover.hasClass 'open'
  spacekey = cover.data('content').spaceKey
  dragging = options.dragging
  window.openSpace = spacekey
  

  loadElements spacekey, (elements) ->

    parentCollection = $('.open.collection')
    parentCover = $('.open.cover')
    prevSliding = cover.prevAll('.sliding')
    nextSliding = cover.nextAll('.sliding')
    
    collection = coverToCollection cover, elements    
    parentCollection.removeClass('open').addClass 'closed'
    parentCover.removeClass('open').addClass 'closed'
    cover.addClass('open').removeClass('draggable').removeClass('closed')
    prevSliding.removeClass 'sliding'
    nextSliding.removeClass 'sliding'
      
    if dragging?
      padding.insertAfter collection.find('.addElementForm')
    
    elements.addClass('sliding').css({ x: xTransform(cover) })
    sliderInit elements
    
    # Remember where we were  
    window.pastState.scrollLeft = $(window).scrollLeft()
    window.pastState.docWidth   = $(window.document).width()
    $(window).scrollLeft 0

    parentCover.velocity
      properties:
        translateX: [ (() -> -$(@).width()), xForceFeedSelf ]
      options: { complete: () -> parentCover.hide() }

    nextSliding.velocity
      properties:
        translateX: [ $(window).width(), xForceFeedSelf ]
      options: { complete: () -> nextSliding.hide() }

    prevSliding.velocity
      properties:
        translateX: [ (() -> -$(@).width()), xForceFeedSelf ]
      options: { complete: () -> prevSliding.hide() }

    cover.siblings('.collectionContent').velocity {
      properties: { opacity: [1, 0] }
    }

    setTimeout collectionRealign, 50

#   If leaving root collection, animate in back button
    if parentCover.hasClass('root')
      $('header.main .backButton').addClass 'visible'
      moveBackButton(32)

collectionClose = (draggingElement) ->
  closingCover = $('.open.cover')
  return if closingCover.hasClass 'root'
  closingSpacekey = closingCover.data('content').spaceKey

  edgeWidth -= 32

  closingCollection = closingCover.parent()
  closingChildren = collectionChildren()
 
  closingCollection.addClass('closed').removeClass('open')
  closingChildren.css('zIndex', 0).removeClass('sliding')

  parentCollection = closingCollection.parent().parent()
  parentChildren = collectionChildren parentCollection
  # console.log 'parent children', parentChildren
  parentCover = parentCollection.children('.cover')

  parentSpacekey = parentCover.data('content').spaceKey

  parentCollection.addClass('open').removeClass('closed')
  parentChildren.show().addClass 'sliding'
  parentCover.addClass('open').removeClass('closed')

  # If entering root collection, animate out back button
  if parentCover.hasClass('root')
    $('header.main .backButton').removeClass 'visible'
    moveBackButton(0)
  
  if draggingElement?
    draggingElement.
      removeClass('dragging').
      addClass('sliding').
      css({scale: 1, zIndex: draggingElement.data('oldZIndex')})
    draggingElement.insertAfter parentCollection.find('.addElementForm')    

    content = parentChildren.not('.addElementForm')
    elementOrder = JSON.stringify(content.get().map (elem) -> +elem.id)
    addToCollection(draggingElement, parentSpacekey)
    console.log "Emitting reorderElements"
    socket.emit 'reorderElements', { elementOrder, spaceKey: parentSpacekey }

  closingCollection.
    data('width', 0).
    children('.collectionContent').velocity {
      properties: { opacity: [0, 1] }
    }

  closingCover.
    addClass('closed').
    removeClass('open').
    addClass('draggable').
    addClass('sliding').
    insertBefore closingCollection
  console.log closingCover
  $(document.body).css width: window.pastState.docWidth
  $(window).scrollLeft window.pastState.scrollLeft
  $("body").css("overflow", "hidden")
  # collectionRealignDontScale()
  
  realign()
  setTimeout (() ->
    closingCollection.remove()
    window.openSpace = parentCollection.children('.cover').data('content').spaceKey
    $("body").css("overflow", "visible")

  ), openCollectionDuration
  
collectionChildren = (collection) ->
  collection ?= $('.collection.open')
  cover = collection.children('.cover')
  elements = collection.children('.collectionContent').children('.element')
  elements.add cover

collectionOfElement = () ->
  $(@).parent().parent()

realign = (animate) ->
  sliding = collectionChildren().filter('.sliding')
  # console.log {sliding}
  lastX  = 0
  maxX   = -Infinity
  zIndex = sliding.length
  
  sliding.each () ->

    $(@).data 'scroll_offset', lastX
    collection = $(@).parent().parent()
    
    if $(@).hasClass('cover') and $(@).hasClass('open')
      $(@).css { zIndex: (sliding.length*3) }
#   If at root level and elem is add element form, to prevent form from being on top at root level
    else if $(@).hasClass('addElementForm') and not $('.root.open').length # (puts add element card at back on root level
      $(@).css { zIndex: (sliding.length*3) - 1 }
    else
      $(@).css { zIndex: zIndex++ }

    $(@).removeData 'oldZIndex'
    slidingPlace.call @, animate
    width = $(@).data('width') or $(@).find('.card').width()
    if collection.hasClass('closing')
      width = 0
    lastX += width + margin
  
  maxX = lastX - sliding.last().width()/2
  $(@).data { maxX }
  maxX

collectionRealign = (animate) ->
  maxX = realign.call @, animate
  $(document.body).css { width: maxX + $(window).width()/2}
  $("body").css("overflow", "hidden")
  setTimeout (() -> $("body").css("overflow", "visible")), openCollectionDuration

collectionRealignDontScale = (animate) ->
  realign animate
 
collectionScroll = () ->
  collectionChildren().filter('.sliding').each () ->
    slidingPlace.call @, false

collectionElemAfter = (x) ->
  # Get the element that the mouse is over
  for html in collectionChildren().filter('.sliding').not('.addElementForm')
    child = $(html)
    if parseInt(child.css('x')) + child.width() > x
      return child
  $()
  
moveBackButton = (x) ->
  $('header.main .backButton').velocity
    properties:
      translateX: x
    options:
      easing: openCollectionCurve
      duration: 1000