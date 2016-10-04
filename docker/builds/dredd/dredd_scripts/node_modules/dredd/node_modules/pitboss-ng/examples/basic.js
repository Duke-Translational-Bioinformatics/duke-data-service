var Pitboss = require('../').Pitboss;

var untrustedCode = "var a = !true;\n (a || foo)";

var sandbox = new Pitboss(untrustedCode, {
  memoryLimit: 64*1024,
  timeout: 5*1000,
  heartBeatTick: 500
});

sandbox.run({
  context: {
    'foo': 'bar',
    'key': 'value'
  },
  libraries: {
    'crypto': 'crypto'
  }
}, function callback (err, result) {
  sandbox.kill();
  if (err) {
    console.error('An Error in sandbox happened:', err);
    return;
  }
  console.log('Result is:', result); // prints "Result is: bar"
});
