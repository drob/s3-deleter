S3-Deleter
=========

A writable stream that batch-deletes files from s3, via the excellent [knox]. Designed for use with [s3-lister].

[knox]: https://npmjs.org/package/knox
[s3-lister]: https://npmjs.org/package/s3-lister

## Examples

These code snippets show some of the things you can do with two streams and a knox client.

Deleting all the files in a folder:
```javascript
var client = knox.createClient({
  key    : '<api-key-here>',
  secret : '<secret-here>',
  bucket : 'great-bucket'
});

var lister = new S3Lister(client, {prefix : 'folder/i/dislike'});
var deleter = new S3Deleter(client);

deleter
  .on('error',  function (err) { console.log('Error!!', err); })
  .on('finish', function ()    { console.log 'All done!' });
lister.pipe(deleter);
```

Deleting all the files in a bucket that are more than one week old:
```javascript
var client = knox.createClient({
  key    : '<api-key-here>',
  secret : '<secret-here>',
  bucket : 'great-bucket'
});

var lister = new S3Lister(client);
var deleter = new S3Deleter(client);

deleter
  .on('error',  function (err) { console.log('Error!!', err); })
  .on('finish', function ()    { console.log 'All done!' });

var oneWeekAgo = Date.now() - 1000 * 60 * 60 * 24 * 7;
lister
  .on('error', function (err)  { console.log('Error!!', err); })
  .on('end',   function ()     { deleter.end(); })
  .on('data',  function (file) {
    if (parseInt(file.LastModified) < oneWeekAgo) {
      deleter.write(file);
    }
  });
```

## Usage

#### new S3Deleter(client, options)

* client - a knox client
* options - hash of options

In addition to the standard writable stream settings, `S3Deleter` supports:
* batchSize - size of batches to delete at a time, up to 1000

## Running Tests

To run the test suite, create a file named `./test/auth.json`, containing your S3 bucket credentials as a JSON, a la:

```json
{
  "bucket": "my-bucket",
  "region": "us-standard",
  "key": "<api-key>",
  "secret": "<secret-key>"
}
```
