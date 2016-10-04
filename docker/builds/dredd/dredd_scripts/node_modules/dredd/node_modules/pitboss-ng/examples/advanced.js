var Pitboss = require('../').Pitboss;

var untrustedCode = "if (typeof returnMe === 'undefined') {\n\
  var returnMe = { theArray: [] };\n\
}\n\
var sortAsNumbers = function (a, b) {\n\
  var aInt = parseInt(a, 10), bInt = parseInt(b, 10);\n\
  if (a === b) {\n\
    return 0;\n\
  } else if (a < b) {\n\
    return -1;\n\
  }\n\
  return 1;\n\
};\n\
console.log('message from VM: returnMe =', returnMe);\n\
\n\
returnMe.theArray.sort(sortAsNumbers);\n\
returnMe;\n\
";

var sandbox = new Pitboss(untrustedCode, {
  memoryLimit: 64*1024,
  timeout: 5*1000,
  heartBeatTick: 500
});

var returnMe = {
  theArray: ['-1', '-5', '10', '15', '-3', '0', '20', '21', '-7', '4']
};

sandbox.run({
  context: {
    returnMe: returnMe
  },
  libraries: ['console']
}, function callback (err, result) {
  sandbox.kill();
  if (err) {
    console.error('An Error in sandbox happened:', err);
    return;
  }
  console.log('Local variable is not sorted (touched):', returnMe.theArray);
  console.log('Result is an array of numbers (sorted):', result.theArray);
});
