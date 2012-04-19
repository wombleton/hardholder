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
      stats = _.map(stats, (stat) ->
        standard =  _.include(['2d6 - 1', '2d6', '2d6 + 1', '2d6 + 2', '2d6 + 3'], stat.roll)
        modifier = if standard then stat.roll.replace(/2d6|\s/g, '') else null
        return {
          label: stat.label
          roll: stat.roll
          custom: not standard
          modifier: modifier
        }
      )
      return {
        name: name
        stats: stats
      }
    )
    while collection.length < 8
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
          res.send('')
        )
      else
        res.send('')
    )
  else
    res.send('invalid data', 400)
)
