assert = require 'assert'
async = require 'async'
auth = require './auth.json'
knox = require 'knox'
S3Deleter = require '../'
S3Lister = require 's3-lister'

client = knox.createClient auth
folder = '_s3-deleter-test'

touchFiles = (numFiles, callback) ->
  filenames = ("#{folder}/#{n}.txt" for n in [0...numFiles])
  touch = (filename, callback) ->
    headers = {'Content-Type': 'text/plain'}
    client.putBuffer new Buffer(filename), filename, headers, callback
  async.each filenames, touch, callback

deleteFiles = (callback) ->
  lister = new S3Lister client, {prefix: folder}
  deleter = new S3Deleter client, {batchSize: 10}
  deleter.on 'error', callback
  deleter.on 'finish', callback
  lister.pipe deleter

assertFolderEmpty = (callback) ->
  client.list {prefix: folder}, (err, result) ->
    return callback err if err
    assert.equal result.Contents.length, 0
    callback()

describe 'S3Deleter', () ->
  this.timeout 10000

  it 'should put 5 files', (done) ->
    touchFiles 5, done

  it 'should delete all the files when fewer than batchSize files are present', (done) ->
    async.series [deleteFiles, assertFolderEmpty], done

  it 'should put 10 files', (done) ->
    touchFiles 10, done

  it 'should delete all the files when exactly batchSize files are present', (done) ->
    async.series [deleteFiles, assertFolderEmpty], done

  it 'should put 35 files', (done) ->
    touchFiles 35, done

  it 'should delete all the files when multiple batches are present', (done) ->
    async.series [deleteFiles, assertFolderEmpty], done

  it 'should handle a case in which an empty stream is piped', (done) ->
    deleteFiles done

  it 'should handle ends before any stream writes', (done) ->
    deleter = new S3Deleter client
    deleter.on 'error', done
    deleter.on 'finish', done
    deleter.end()
