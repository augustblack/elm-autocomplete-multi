express = require('express')
fs = require 'fs'
app = express()

words=[]
import_words = () =>
  filename = __dirname + '/words.txt'
  fs.readFile filename, 'utf8', (err, data)=>
    words = data.split '\n'
    console.log "words", words.length


cors_for_all = (req, res, next) ->
  res.set('Access-Control-Allow-Origin', '*')
  res.set('Access-Control-Allow-Methods', 'POST,  GET, PUT, DELETE')
  res.set('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, maxversion')
  res.set('Access-Control-Allow-Max-Age', 3600)
  if ('OPTIONS' == req.method)
    return res.status(200).send()
  else
    return next()


app.get '/word/:term', 
  cors_for_all,
  (req, res, next) => 
    reg =new RegExp req.params.term 
    found = words.filter (w)=> 
      return reg.test w
    page = 0
    page = parseInt req.query.page if req.query.page
    perPage = 10
    perPage = parseInt req.query.perPage if req.query.perPage
    start = page*perPage
    end = start + perPage
    found = found[start..end]
    res.json found

import_words()

server = app.listen 3000, () =>
  host = server.address().address
  port = server.address().port
  console.log('Example app listening at http://%s:%s', host, port)
