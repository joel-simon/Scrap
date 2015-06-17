makeSpaceCreator = (elem) ->
  createNew = () ->
    #turn new-space-button into a real space
    elem.removeClass 'add'
    elem.off 'click', createNew

    #create a new new-space button
    addSpaceButton = $('<div class="spacePreview add"><h1 class="spaceName">New Space</h1></div>')
    $('section.content').prepend addSpaceButton
    makeSpaceCreator addSpaceButton

    $.post '/s/new', { name: 'New Space' }, (spaceKey) ->
      history.pushState {name: "/s/#{spaceKey}"}, "", "/s/#{spaceKey}"
      elem.addClass spaceKey
      enterSpace spaceKey, elem, () ->
          $('.headerSpaceName').trigger 'click'
      elem.on 'click', () ->
        enterSpace spaceKey, elem


  elem.on 'click', createNew

$ -> makeSpaceCreator $('.spacePreview.add')
