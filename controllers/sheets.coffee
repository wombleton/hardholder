{ app } = require('../app')
{ User } = require('../models/user')
users = require('./users')
flow = require('flow')
{ Sheet } = require('../models/sheet')
_ = require('underscore')

app.get('/sheets', (req, res) ->
  users.auth((req), (user) ->
    if user
      { sheets } = user
    else
      sheets = []
    collection = _.map(sheets, (sheet) ->
      { name, stats } = sheet
      return {
        name: name
        stats: stats
      }
    )
    while collection.length < 6
      collection.push(
        name: 'Blank'
        stats: []
      )
    res.partial('play/sheets',
      locals:
        sheets: collection
    )
  )
)

app.post('/sheets', (req, res) ->
  if _.isArray(req.body?.sheets)
    sheets = _.map(req.body.sheets, (sheet) ->
      new Sheet(sheet)
    )
    users.auth((req), (user) ->
      if user
        debugger
        User.update( { _id: user.id }, { $set: { sheets: req.body.sheets } }, {}, (err) ->
          debugger
          res.send('')
        )
      else
        res.send('')
    )
  else
    res.send('invalid data', 400)
)
