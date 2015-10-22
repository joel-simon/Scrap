models   = require '../../models'
async    = require 'async'
s3 = require '../adapters/s3.coffee'
request = require 'request'
elementRenderer = require '../modules/elementRenderer.coffee'
# webPreviews = require '../modules/webPreviews.coffee'
# thumbnails = require '../modules/thumbnails.coffee'
# videoScreenshot = require '../modules/videoScreenshot.coffee'
newElements = require './newElements'

getType = (s, cb) ->
  jar = request.jar()
  options =
    url: s
    followAllRedirects: true
    jar: jar

  request.head options, (err, res) ->
    if err || !res
      return cb 'text'
    contentType = res.headers['content-type']
    host = res.socket._httpMessage._headers.host
    # return cb 'gif' if contentType.match /^image\/gif/
    return cb 'image' if contentType.match /^image\//
    return cb 'video' if contentType.match /^video\//
    if contentType.match /^text\/html/
      return cb 'soundcloud' if host is 'soundcloud.com'
      return cb 'youtube' if host is 'www.youtube.com'
      return cb 'website'
    return cb 'file'# if contentType.match /^application\//


checkForStackDelete = (sio, socket, data, callback) ->
  { spaceKey, parentSpaceKey } = data
  # console.log spaceKey, parentSpaceKey

  models.Space.find({
    where: { spaceKey }
    include: [ models.Element ]
  }).complete (err, space) ->
    console.log space.spaceKey, space.hasCover, space.root, space.elements.length
    return callback err if err?
    return callback null if space.hasCover or space.root
    return callback null if space.elements.length > 1

    params = { spaceKey: parentSpaceKey, elemId: space.elements[0].id }
    module.exports.moveToCollection sio, socket, params, (err) ->
      return callback(err) if err
      removeParams = { elementId: space.coverId, spaceKey: parentSpaceKey }
      module.exports.removeElement sio, socket, removeParams, (err) ->
        return callback(err) if err?
        space.destroy().then callback

# checkForDelete null, null, { spaceKey:'aecba014', parentSpaceKey: 'dbdb550d' }, (err) ->
#   console.log err

module.exports =
  # create a new element and save it to db
  newElement : (sio, socket, data, callback) =>
    spaceKey = data.spacekey
    data.content = decodeURIComponent data.content
    userId = socket.handshake.session.userId
    console.log 'Received content:'
    console.log "\tuserId: #{userId}"
    console.log "\tspaceKey: #{spaceKey}"
    console.log "\tcontent: #{data.content}"

    done = (err, attributes) ->
      return callback err if err
      models.Space.find({ where: { spaceKey }, include: models.User }).complete (err, space) =>
        return callback err if err? or !space
        attributes.SpaceId = space.id
        models.Element.create(attributes).complete (err, element) =>
          return callback err if err?
          # console.log space.elementOrder
          space.elementOrder.unshift(element.id)
          # console.log space.elementOrder
          space.save()
          html = elementRenderer space, element
          sio.to(spaceKey).emit 'newElement', { html, spaceKey }
          return callback null
    
    getType data.content, (contentType) ->
      console.log "\tcontentType: #{contentType}"
      attributes =
        creatorId: userId
        contentType: contentType
        content: data.content

      if contentType of newElements
        newElements[contentType] spaceKey, attributes, done
      else
        done null, attributes

  # delete the element
  removeElement : (sio, socket, data, callback) =>
    userId   = socket.handshake.session.currentUserId
    id       = data.elementId
    spaceKey = data.spaceKey

    return callback('no id passed to removeElement') unless id
    return callback('no spaceKey passed to removeElement') unless spaceKey
    
    console.log "Delete element #{id} in #{spaceKey}"
    q1 = "
        DELETE FROM \"Elements\"
        WHERE \"id\"=:id
        RETURNING \"contentType\", content
      "
    models.sequelize.query(q1, null, null, { id }).complete (err, results) ->
      return callback err if err?
      console.log 'emiting removeElement', { id, spaceKey }
      sio.to(spaceKey).emit 'removeElement', { id, spaceKey }
      # callback null
      setTimeout (() ->
        checkForStackDelete sio, socket, data, callback
      ), 300
      # type = results[0].contentType
      # content = results[0].content
      # if type in ['gif', 'image']
      #   s3.deleteImage { spaceKey, key: content, type }, (err) ->
      #     console.log err if err
      # if type in ['file', 'video']
      #   s3.delete {key: content}, (err) ->
      #     console.log err if err

  moveToCollection: (sio, socket, data, callback) ->
    { elemId, spaceKey } = data
    console.log "move to collection data:", data
    q = "
        UPDATE \"Elements\"
        SET \"SpaceId\" = (Select id from \"Spaces\" WHERE \"spaceKey\"=:spaceKey)
        WHERE \"id\"=:elemId
        "
    models.sequelize.query(q, null, null, data).complete (err, results) ->
      return callback err if err?
      return callback null
  
  updateElement : (sio, socket, data, callback) =>
    userId = socket.handshake.session.currentUserId
    { spaceKey, content, elementId } = data
    id = +elementId
    models.Element.update({content}, {id}).complete (err) ->
      return callback err if err
      data.userId = userId
      sio.to("#{spaceKey}").emit 'updateElement', data
