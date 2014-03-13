async = require 'async'
Writable = require('stream').Writable

MAX_BATCH_SIZE = 1000

module.exports = class S3Deleter extends Writable
  constructor: (client, options) ->
    @client = client
    @deleteQueue = []

    options ?= {}
    @batchSize = options.batchSize ? MAX_BATCH_SIZE
    if @batchSize > MAX_BATCH_SIZE
      throw Error "Not allowed to delete more than #{MAX_BATCH_SIZE} items at once."
    options.objectMode = true
    super options

  _write: (file, enc, callback) ->
    # If we're all done, delete whatever's left in our queue.
    if file is null
      deletions = (this._deleteBatch for n in [0...@deleteQueue.length/@batchSize])
      return async.parallel deletions, callback

    # Handle direct strings or knox results.
    key = file.Key ? file
    @deleteQueue.push key
    if @deleteQueue.length < @batchSize
      callback()
    else
      this._deleteBatch(callback)

  _deleteBatch: (callback) =>
    # Lop batchSize items off the queue and delete them.
    toDelete = @deleteQueue[...@batchSize]
    @deleteQueue = @deleteQueue[@batchSize..]
    @client.deleteMultiple toDelete, (err) ->
      callback err

  # Wrap end to make sure we clear out whatever's in the queue.
  end: ->
    @write null, null, (err) =>
      return @emit 'error', err if err
      super()
