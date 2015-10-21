stackCreate = (cover) ->
  cover.addClass('stack').removeClass('cover').empty()
  # $('div').addClass('stack').data('content', {spaceKey})

stackPopulate = (stack) ->
  spaceKey = stack.data('content').spaceKey
  loadElements spaceKey, (elements) ->
    stackAdd stack, elements.not('.addElementForm')

stackAdd = (stack, elements) ->
  # elements = elements.not('.cover')#.slice(1, 6)
  elements.css('transform', 'none').removeClass 'sliding'

  stack.append elements
  max = 0
  spacing = 20
  for i in [0...stack.children().length]
    e = $(stack.children()[i])
    offset = i*spacing
    max = Math.max(max, offset+e.width())
    e.css 'left', offset

  stack.data 'width', max
  collectionRealign()

# createStack = (cover) ->
#   # stack = $('div').addClass('stack').

#   # stack = $('div').addClass('stack')
#   stack = cover.
#             removeClass('cover').
#             addClass('stack').
#             empty()
#   # $.each cover.prop("attributes"), () ->
#   #   stack.attr @name, @value

#   spaceKey = stack.data('content').spaceKey
#   spacing = 25
#   loadElements spaceKey, (elements) ->
#     elements = elements.not('.cover').slice(1, 6)
#     stack.append elements
#     max = 0
#     for i in [0...elements.length]
#       e = $(elements[i])
#       offset = i*spacing
#       max = Math.max(max, offset+e.width())
#       e.css 'left', offset

#     # stack.data 'width', max
#     stack.width max
#     realign()
#     