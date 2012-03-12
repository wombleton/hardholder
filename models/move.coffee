db = require('../db').db
mongoose = require('mongoose')
Schema = mongoose.Schema
dateformat = require('dateformat')
MD_TAGS = 'b|em|i|li|ol|p|strong|ul|br|hr'
md = require('node-markdown').Markdown
_ = require('underscore')

slug = (s) -> (s || '').replace(/\s+/g, '-').replace(/[^a-zA-Z0-9-]/g, '').replace(/[-]+/g, '-').toLowerCase()

getOffset = (page) ->
  page ||= 1
  page = 1 if page < 1
  (page - 1) * PAGE_SIZE

parseTags = (tags) ->
  tags = if _.isArray(tags) then tags.join(' ') else tags || ''
  _.map(_.compact(tags.split(/\s+/)), (tag) ->
    tag.replace(/[^a-z0-9-_]/gi, '').toLowerCase()
  )

MoveSchema = new Schema({
  condition: {
    default: '',
    type: String,
    validate: [
      (v) -> (v || '').match(/\w/)
      'empty'
    ]
  }
  definition: String
  meta: {
    downvotes: {
      type: Number
      default: 0
    }
    slug: String
    upvotes: {
      type: Number
      default: 0
    }
  }
  ts: {
    default: -> new Date().getTime()
    index: true
    type: Number
  }
  stat: {
    type: String
  },
  authors: String
  source: String
  tags: {
    default: []
    index: true
    set: (tags) -> parseTags(tags)
    type: [String]
  }
})

MoveSchema.pre 'save', (next) ->
  @meta.slug = slug(@condition)
  next()
MoveSchema.virtual('url').get -> '/moves/' + this.meta.slug

MoveSchema.virtual('definition_markdown').get -> md((this.definition || '').replace(/</g, '&lt;').replace(/>/g, '&gt;'), true, MD_TAGS)

MoveSchema.virtual('edit_url').get -> '/moves/' + this._id + '/edit'

MoveSchema.virtual('definition_url').get -> '/moves/' + this.meta.slug  + '/' + this._id

MoveSchema.virtual('id_url').get -> '/moves/' + this._id

MoveSchema.virtual('date_display').get -> dateformat(new Date(this.ts), 'dd mmm yyyy')

mongoose.model 'Move', MoveSchema

module.exports.Move = db.model('Move')
