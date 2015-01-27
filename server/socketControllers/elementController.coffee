models   = require '../../models'
async    = require 'async'
webPreviews = require '../modules/webPreviews.coffee'
memCache = {}

module.exports =
  # create a new element and save it to db
  newElement : (sio, socket, data, spaceKey, callback) =>
    console.log 'Received content', data.content, typeof data.content
    done = (attributes) ->
      models.Space.find(where: { spaceKey }).complete (err, space) =>
        return callback err if err?
        attributes.SpaceId = space.id
        models.Element.create(attributes).complete (err, element) =>
          return callback err if err?
          sio.to(spaceKey).emit 'newElement', { element }
    
    attributes =
      creatorId: data.userId
      contentType: data.contentType
      content: data.content
      caption: data.caption
      x: data.x
      y: data.y
      z: data.z
      scale: data.scale

    if data.contentType is 'website'
      url = decodeURIComponent data.content
      webPreviews url, (err, pageData) ->
        if err?
          console.log url, err, pageData
          attributes.content = JSON.stringify { 
            title: url.match(/www.([a-z]*)/)[1]
            url: encodeURIComponent(url)
            description: ''
          }
        else
          pageData.url = encodeURIComponent pageData.url
          attributes.content = JSON.stringify pageData
        done attributes
    else
      done attributes
        

  # delete the element
  removeElement : (sio, socket, data, spaceKey, callback) =>
    id = data.elementId

    query = "DELETE FROM \"Elements\" WHERE \"id\"=:id"

    elementShell = models.Element.build()
    models.sequelize.query(query, null, null, { id })
      .complete (err, result) ->
        return callback err if err?
        sio.to(spaceKey).emit 'removeElement', { id }
        callback()

  updateElement : (sio, socket, data, spaceKey, callback) =>
    data.id = +data.elementId
    data.final = JSON.parse data.final
    query = "UPDATE \"Elements\" SET"
    query += " \"x\"=:x," if data.x?
    query += " \"y\"=:y," if data.y?
    query += " \"z\"=:z," if data.z?
    query += " \"scale\"=:scale" if data.scale?
    # remove the trailing comma if necessary
    query = query.slice(0,query.length - 1) if query[query.length - 1] is ","
    query += " WHERE \"id\"=:id RETURNING *"

    # new element to be filled in by update
    if data.final
      element = models.Element.build()
      models.sequelize.query(query, element, null, data).complete (err, result) ->
        return callback err if err?
        sio.to("#{spaceKey}").emit 'updateElement', { element: result }
        callback()
    else
      userId = data.userId
      element =
        x : parseInt data.x
        y : parseInt data.y
        z : parseInt data.z
        scale : parseInt data.scale
        id: data.id
      # console.log userId
      sio.to("#{spaceKey}").emit 'updateElement', { element, userId }
