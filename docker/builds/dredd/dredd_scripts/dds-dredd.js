var Dredd = require('dredd');

// allow self-signed certs
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// suppress warning message if more than 10 listeners are added to an event - this is needed here to suppress
// warning messages from the node-rest-client package...
require('events').EventEmitter.defaultMaxListeners = Infinity;

configuration = {
  server: process.env.HOST_NAME, // your URL to API endpoint the tests will run against
  //For debug: export HOST_NAME=https://dukeds-dev.herokuapp.com/api/v1
  //Get JWT: https://dukeds-dev.herokuapp.com/apiexplorer
  //export MY_GENERATED_JWT=
  options: {

    'path': ['./apiary.apib'],  // Required Array if Strings; filepaths to API Blueprint files, can use glob wildcards

    'dry-run': false, // Boolean, do not run any real HTTP transaction
    'names': false,   // Boolean, Print Transaction names and finish, similar to dry-run

    'level': 'info', // String, log-level (info, silly, debug, verbose, ...)
    'silent': false, // Boolean, Silences all logging output

    'only': [

            ], // Array of Strings, run only transaction that match these names

    'header': ['Accept: application/json', 'Authorization: '.concat(process.env.MY_GENERATED_JWT)], // Array of Strings, these strings are then added as headers (key:value) to every transaction
    'user': null,    // String, Basic Auth credentials in the form username:password

    'hookfiles': [ 'hooks.js'
                ], // Array of Strings, filepaths to files containing hooks (can use glob wildcards)

    'reporter': [], // Array of possible reporters, see folder src/reporters

    'output': [],    // Array of Strings, filepaths to files used for output of file-based reporters

    'inline-errors': false, // Boolean, If failures/errors are display immediately in Dredd run

    'color': true,
    'timestamp': false
  }
  // 'emitter': EventEmitterInstance // optional - listen to test progress, your own instance of EventEmitter

  // 'hooksData': {
  //   'pathToHook' : '...'
  // }

  // 'data': {
  //   'path/to/file': '...'
  //}
}

var dredd = new Dredd(configuration);

dredd.run(function (err, stats) {
  console.log(err);
  console.log(stats);
  console.log(stats['failures']);
  if (stats['failures']>0)
  {
    console.log("There was one or more failures, check log above.");
    return process.exit(1)
  }
else
  {
     return process.exit(0)
  }
  // otherwise stats is an object with useful statistics
});
