$ -> 
  elements = $('.draggable')
  elements.click () ->
    url = window.location+"s/"+$(@).data().spaceid

    $('<iframe />', {
      name: 'spaceFrame'
      class:'spaceFrame'
      src: url
    }).
    click((event)->
      event.preventDefault()
      event.stopPropagation()
    ).
    prependTo($(@)).
    ready () =>
      setTimeout(() =>
        $('.home').show()
        $(@).addClass("open")
      ,500)
    
