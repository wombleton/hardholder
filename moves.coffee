dateformat = require('dateformat')
flow = require('flow')
md = require('node-markdown').Markdown
MD_TAGS = 'b|em|i|li|ol|p|strong|ul|br|hr'
Mongoose = require('mongoose')
Schema = Mongoose.Schema
_ = require('underscore')
MoveSchema
PAGE_SIZE = 50

slug = (s) -> (s || '').replace(/\s+/g, '-').replace(/[^a-zA-Z0-9-]/g, '').replace(/[-]+/g, '-').toLowerCase()

getOffset = (page) ->
  page ||= 1;
  page = 1 if page < 1
  (page - 1) * PAGE_SIZE

parseTags = (tags) ->
  tags = if _.isArray(tags) then tags.join(' ') else tags || '';
  _.map(_.compact(tags.split(/\s+/)), (tag) -> tag.replace(/[^a-z0-9-_]/gi, ''))    

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

Mongoose.model 'Move', MoveSchema

validate = (move) ->
  condition = move.condition || ''
  definition = move.definition || ''
  errors = []
  
  roll = definition.match(/roll\s?[+]\s?(\w+)/i)
  move.stat = stat = (roll && roll[1]) || ''
  
  if condition.match(/^\s*(new|tagged|\d+)\s*$/)
    errors.push('Title cannot be "new", "tagged" or just numbers.')
    
  unless condition.match(/\w/)
    errors.push('Title cannot be blank.')
    
  unless stat.match(/\w/)
    errors.push('Definition must include what to roll, such as "roll +hot".');    
  
  unless definition.match(/On\s+(a\s+)?7\s?-\s?9/i)
    errors.push('Definition must include "on a 7-9".')
    
  unless definition.match(/On\s+(a\s+)?10[+]/i)
    errors.push('Definition must include "On 10+".')
  errors;

module.exports.route = (server, Move) ->
  server.get '/moves', (req, res) ->
    offset = getOffset(req.query.page)
    query = Move.find()
      .desc('ts')
      .limit(PAGE_SIZE)
      .skip(offset)
      .run (err, moves) ->
        res.header('Cache-Control', 'no-cache')
        res.render 'moves/index', 
          locals:
            page: offset / PAGE_SIZE
            moves: moves
            user: req.getAuthDetails().user    

  server.post '/moves', (req, res) ->
    move = new Move(req.body && req.body.move)
    errors = validate(move)
    if errors.length == 0
      move.save (err) ->
        if err
          res.redirect('/moves/new');
        else
          res.redirect(move.url);
      
    else
      res.redirect('/moves/new');
    

  server.post '/moves/:id', (req, res) ->
    Move.findById(req.params.id, (err, move) ->
      move = _.extend(move, req.body.move);
      move.save (err) ->
        if err
          res.render('moves/edit', {
            locals: {
              move: move
            }
          });
        else
          res.redirect(move.url);
    );
  
  server.get '/moves/new', (req, res) ->
    res.render 'moves/new',
      locals:
        context: 'new'
        user: req.getAuthDetails().user    
        

  server.get '/moves/tagged/:tags', (req, res) ->
    offset = getOffset(req.query.page)
    tags = parseTags(req.params.tags)
    if tags.length == 0
      res.redirect('/moves');
    else
      Move.find({ tags: { $all: tags } })
          .desc('ts')
          .limit(PAGE_SIZE)
          .skip(offset)
          .run (err, moves) ->
            res.render 'moves/index',
              locals:
                moves: moves,
                tags: tags.join ' '
                user: req.getAuthDetails().user    
  
  server.get '/moves/rss', (req, res) ->
    query = Move.find()
      .desc('ts')
      .limit(PAGE_SIZE)
      .run (err, moves) -> 
        res.header('Content-Type', 'application/xml; charset=utf-8');
        res.header('Cache-Control', 'no-cache');
        res.render('moves/rss', { locals: {
          layout: false,
          moves: moves
        }});
  
  server.get '/moves/:slug', (req, res) ->
    query = Move.find({ 'meta.slug': req.params.slug });
    query.desc('meta.upvotes');
    query.exec (err, moves) ->
      if moves.length == 0
        res.render '404',
          locals:
            condition: req.params.slug
            user: req.getAuthDetails().user    
          status: 404 
      else
        res.render 'moves/index', 
          moves: moves
          user: req.getAuthDetails().user    
  
  server.post '/preview', (req, res) ->
    move = new Move(req.body.move)
    errors = validate(move);

    res.render 'moves/preview', {
      layout: false,
      locals: {
        errors: errors,
        move: move
      }
    }

  vote = (req, res, vote) ->
    flow.exec(
      (-> Move.findById(req.params.id, this))
      , ((err, move) ->
        if move
          move.meta[vote]++;
          this.move = move;
          move.save(this);
        else
          @())
      ,((err) -> res.redirect(req.headers.referer || '/moves'))
    );
  server.get '/moves/:id/up', (req, res) -> vote(req, res, 'upvotes')
  
  server.get '/moves/:id/down', (req, res) -> vote(req, res, 'downvotes')

  server.get '/moves/:id/edit', (req, res) ->
    if req.isAuthenticated()
      Move.findById req.params.id, (err, move) ->
        res.render 'moves/edit.jade',
          locals:
            move: move
            user: req.getAuthDetails().user    
    else
      req.session.authenticated_redirect_url = req.url
      res.redirect '/login'