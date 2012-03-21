{ app } = require('../app')
flow = require('flow')
{ Sheet } = require('../models/sheet')
_ = require('underscore')

app.get('/sheets', (req, res) ->
  query = Sheet.find()
    .run((err, sheets) ->
      while sheets.length < 6
        sheets.push(
          name: ''
          stats: []
        )
      res.partial('play/sheet',
        collection: sheets
      )
    )
)
app.post('/sheets', (req, res) ->
  if _.isArray(req.body?.sheets)
    sheets = _.map(req.body.sheets, (sheet) ->
      new Sheet(sheet)
    )
    Sheet.find().run((err, to_remove) ->
      debugger
      flow.exec(
        ->
          if to_remove.length > 0
            _.each(to_remove, (sheet) ->
              sheet.remove(@MULTI())
            , @)
          else
            @()
        ->
          if sheets.length > 0
            _.each(sheets, (sheet) ->
              sheet.save(@MULTI())
            , @)
          else
            @()
        ->
          res.send('')
      )
    )
  else
    res.send('invalid data', 400)
)
