'use strict'

window.constants =
  style:
    gutter: 24 / (1/2)
    easing: 'cubic-bezier(0.19, 1, 0.22, 1)'
    globalScale: .5
    duration:
      openArticle: 1000
      hoverArticle: 250
    articleHoverScale: .75
  velocity:
    easing:
      smooth: [20, 10]
      spring: [75, 10]
  dom:
    nav: 'nav.main'
    collectionsMenu: 'ul.collectionsMenu'
    addArticleMenu: '.addArticleForm'
    articleContainer: '#articleContainer'
    collections: 'ul.collectionsMenu li.collection'
    articles: 'article'
    articleMeta: 'footer .meta'

window.scrapState =
  waitingForContent: false
  openArticle: null

$ ->
  window.socket = io.connect()
  window.openCollection = 'recent'

  collectionsMenuController.init $(constants.dom.collectionsMenu)
  containerController.init       $(constants.dom.articleContainer)
  addArticleMenuController.init  $(constants.dom.addArticleMenu)

  articleController.init         $(constants.dom.articles)
  collectionController.init      $(constants.dom.collections)

  # window.pack = new DomCoolTest ( () ->
  #   $(constants.dom.articleContainer).packery()
  # ), 200

  $( constants.dom.articleContainer ).packery()

  $(window).scroll scrollController.onScroll
  scrollController.onScroll()

  $('body').click (event) ->
    console.log 'click body'
    if scrapState.openArticle?
      console.log 'Closeing article', scrapState.openArticle.attr('id')
      articleView.close event, scrapState.openArticle# unless $article.is(':hover')
      scrapState.openArticle = null
      scrollController.enableScroll()



  $('li.recent a, li.labelsButton a').each ->
    $(@).data('hue', Math.floor(Math.random() * 360))
    rotateColor $(@), $(@).data('hue')

  setInterval ->
    $('li.recent a, li.labelsButton a').each ->
      $(@).data('hue', $(@).data('hue') + 30)
      rotateColor $(@), $(@).data('hue')
  , 1000
