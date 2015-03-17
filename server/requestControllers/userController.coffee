models = require '../../models'
spaceController = require './spaceController'
module.exports =
  
  # create a new user and default space, redirect to space
  newUser : (req, res, callback) ->
    { name, email, password } = req?.body
    attributes = { name, email, password }

    models.User.find(where: { email }).complete (err, user) ->
      if user?
        if user.name? and user.password?
          return res.status(400).send 'Duplicate email'

        user.updateAttributes({name, password}).complete (err) ->
          done user
      else
        models.User.create(attributes).complete (err, user) ->
          if err?
            if 'email' of err # not a valid email
              return res.status(400).send 'Not a valid email'
            if err.code == '23505' # not a unique email
              return res.status(400).send 'Not a unique email'
            return res.status(400).send err
          else
            done user
      done = (user) ->
        req.session.currentUserId = user.id
        req.body.space =
          name: "Welcome"
          welcomeSpace: true
        spaceController.newSpace req, res, callback

  # verify login creds, redirect to first space
  login : (req, res, callback) ->
    email = req.body.email
    password = req.body.password

    models.User.find(
      where: { email }
      include: [ models.Space ]
    ).complete (err, user) ->
      return res.status(400).send if err?
      return res.status(400).send "No account found for that email" if not user?
      user.verifyPassword password, (err, result) ->
        return res.status(400).send err if err?
        # render first space on success
        if result
          req.session.currentUserId = user.id
          res.send "/"#"/s/" + user.spaces[0].spaceKey
          callback()
        else
          # res.status 400
          return res.status(400).send 'Incorrect password.'

  logout : (req, res, callback) ->
    req.session.destroy (err) ->
      return callback err if err?
      res.redirect "/"
