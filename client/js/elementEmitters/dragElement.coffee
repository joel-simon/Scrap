draggableOptions = (socket) ->
  start: (event, ui) ->
    elem = $(this)
    window.dontAddNext = true
    screenScale = $('.content').css 'scale'
    $(window).off 'mousemove'
    click.x = event.clientX
    click.y = event.clientY

    initDragOnElem = (_elem) ->
      window.maxZ += 1
      z = window.maxZ
      _elem.zIndex z

      # startPosition.left = ui.position.left
      # startPosition.top = ui.position.top 

      _elem.data 'startPosition', {
        left: parseFloat(_elem.css('left')) * screenScale
        top: parseFloat(_elem.css('top')) * screenScale
      }
    
    initDragOnElem elem
    if elem.data('children')?.length
      for comment in elem.data('children').map((id) -> $('#'+id))
        initDragOnElem comment
        
  drag: (event, ui) ->
    screenScale = $('.content').css('scale')
    diffX = event.clientX - click.x
    diffY = event.clientY - click.y

    dragElem = (elem) ->
      start = elem.data 'startPosition'
      elem.css('left', (event.clientX - click.x + start.left)/screenScale)
      elem.css('top', (event.clientY - click.y + start.top)/screenScale)
      ui.position =
        left: (event.clientX - click.x + startPosition.left) / (screenScale)
        top: (event.clientY - click.y + startPosition.top) / (screenScale)
      
      id = elem[0].id
      x = parseInt Math.round(parseInt(elem.css('left')) - totalDelta.x)
      y = parseInt Math.round(parseInt(elem.css('top')) - totalDelta.y)
      z = parseInt elem.zIndex()
      socket.emit 'updateElement', { x, y, z, elementId: id, userId, final: false }
    
    dragElem $(this)
    if $(this).data('children')?.length
      for comment in $(this).data('children').map((id) -> $('#'+id))
        dragElem comment

  stop: (event, ui) ->
    
    stopElem = (elem) ->
      id = elem.attr('id')
      # Make sure to account for screen drag (totalDelta)
      x = parseInt Math.round(parseInt(elem.css('left')) - totalDelta.x)
      y = parseInt Math.round(parseInt(elem.css('top')) - totalDelta.y)
      z = parseInt elem.zIndex()
      
      window.maxX = Math.max x, maxX
      window.minX = Math.min x, minX

      window.maxY = Math.max y, maxY
      window.minY = Math.min y, minY
      userId = window.userId or null
      socket.emit 'updateElement', { x, y, z, elementId: id, userId, final: true }

    stopElem $(this)
    if $(this).data('children')?.length
      for comment in $(this).data('children').map((id) -> $('#'+id))
        stopElem comment
    else
      makeTextChild $(this)

makeDraggable = (elements, socket) ->
  # console.log elements
  elements.draggable draggableOptions socket
    # .on 'mouseover', ->
      # $(this).data('oldZ', $(this).css 'z-index')
      # $(this).css 'z-index', window.maxZ + 1
    .on 'mouseout', ->
      $(this).css 'z-index', $(this).data 'oldZ'
    .on 'click', ->
      $(window).trigger 'mouseup'
      # socket.emit 'updateElement', { z: $(this).css('z-index'), elementId: $(this).attr 'id' }
$ ->
  socket = io.connect()
  makeDraggable $('article'), socket
