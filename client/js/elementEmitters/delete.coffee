onDelete = (elem) ->
  elementId = elem.attr 'id'
  spaceKey = elem.parent().parent().data 'spacekey'
  socket.emit 'removeElement', { elementId, spaceKey }

makeDeletable = (elem) ->
  elem.find('.elementDeleteButton').click () -> onDelete elem
  console.log elem
$ ->
  $('.slider').each () -> makeDeletable($(@))