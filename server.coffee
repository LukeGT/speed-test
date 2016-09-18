express = require 'express'
app = express()
sass = require 'node-sass-middleware'
coffee = require 'coffee-middleware'

PORT = 20333
CHUNK_SIZE = 128 * 1024
MAX_SIZE = 16 * 1024 * 1024
TEST_DURATION = 2 * 1000

buffer = new Buffer(CHUNK_SIZE)
buffer.fill(0)


app.set 'view engine', 'jade'
app.use(
  '/js'
  express.static __dirname + '/js'
  coffee {
    src: __dirname + '/js'
    compress: true
  }
)
app.use sass {
  src: __dirname + '/css'
  prefix: '/css'
  outputStyle: 'compressed'
}
app.use '/css', express.static __dirname + '/css'


app.get '/', (req, res) ->
  res.render 'index'


app.get '/start', (req, res) ->

  size = +req.query.size
  if size > MAX_SIZE
    size = MAX_SIZE

  count = Math.floor size/CHUNK_SIZE
  for a in [0...count]
    res.write buffer

  res.write buffer.slice(0, size % CHUNK_SIZE)
  res.end()

app.listen PORT, ->
  console.log "Listening on #{PORT}"
