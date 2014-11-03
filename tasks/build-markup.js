var path = require('path');

var Metalsmith = require('metalsmith');
var ignore = require('metalsmith-ignore');
var markdown = require('metalsmith-markdown');
var templates = require('metalsmith-templates');

var smith = new Metalsmith(path.join(__dirname, '..'));

smith.source('src')
    .use(ignore('!**/*.+(md|html)'))
    .use(markdown())
    .use(templates('handlebars'))
    .destination(process.argv[2])
    .clean(false)
    .build(function(err) {
      if (err) {
        throw err;
      }
    });
