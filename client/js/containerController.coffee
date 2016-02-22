window.containerController =
  init: ($container) ->
    isOverArticle = false
    $wrapper      = $('.wrapper')
    
    # Will clicking the wrapper insert a new add form?
    $container.data 'canInsertFormOnClick', false
    
    $container.packery
      itemSelector: 'article'
      isOriginTop: true
      transitionDuration: '0.0s'
      gutter: 0 #constants.style.gutter
      isOriginTop: false

    $container.packery 'bindResize'
    
    $wrapper.mousemove (event) ->
      unless scrapState.openArticle?
        if $("#{constants.dom.articles}:hover").length # If over article
          unless isOverArticle
#             cursorView.end()
            $container.data 'canInsertFormOnClick', false
          isOverArticle = true
        else # If over wrapper but not any article
          if isOverArticle
            cursorView.start '+'
            console.log 'container start'
          else
            cursorView.move event
            $container.data 'canInsertFormOnClick', true
          isOverArticle = false
    
    $wrapper.click (event) ->
      containerView.insertNewArticleForm(event) if $container.data('canInsertFormOnClick')
#       cursorView.end()

    $container.droppable
      greedy: true
      drop: (event, ui) ->
        $collection = ui.draggable
        articleController.removeCollection $collection.parent().parent(), $collection

    $container.css
      width: "#{100/constants.style.globalScale}%"
#       minHeight: "#{85/constants.style.globalScale}vh"
#       maxHeight: $container.height()/8
    $container.velocity
      properties:
        translateZ: 0
        scale: constants.style.globalScale
      options:
        duration: 1
