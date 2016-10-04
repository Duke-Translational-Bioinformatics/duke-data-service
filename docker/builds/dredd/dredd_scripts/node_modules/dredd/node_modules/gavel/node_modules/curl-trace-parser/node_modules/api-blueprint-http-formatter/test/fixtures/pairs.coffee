module.exports.post =
  request:
    method: 'POST'
    uri: '/shopping-cart'
    headers:
      'User-Agent': 'curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8x zlib/1.2.5'
      'Host': 'curltraceparser.apiary.io'
      'Accept': '*/*'
      'Content-Type': 'application/json'
      'Content-Length': '39'
    body: '{ "product":"1AB23ORM", "quantity": 2 }'
  
  response:
    statusCode: '201'
    statusMessage: 'Created'
    headers:
      'Content-Type': 'application/json'
      'Date': 'Sun, 21 Jul 2009 14:51:09 GMT'
      'X-Apiary-Ratelimit-Limit': '120'
      'X-Apiary-Ratelimit-Remaining': '119'
      'Content-Length': '50'
      'Connection': 'keep-alive'
    body: '{ "status": "created", "url": "/shopping-cart/2" }'

module.exports.get =
  request:
    method: 'GET'
    uri: '/shopping-cart'
    headers:
      'User-Agent': 'curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8x zlib/1.2.5'
      'Host': 'curltraceparser.apiary.io'
      'Accept': '*/*'
    body: ''
  
  response:
    statusCode: '200'
    statusMessage: 'Created'
    headers:
      'Content-Type': 'application/json'
      'Date': 'Sun, 21 Jul 2009 14:51:09 GMT'
      'X-Apiary-Ratelimit-Limit': '120'
      'X-Apiary-Ratelimit-Remaining': '119'
      'Content-Length': '50'
      'Connection': 'keep-alive'
    body: '{\n  "items": [\n    {\n      "url": "/shopping-cart/1",\n      "product": "2ZY48XPZ",\n      "quantity": 1,\n      "name": "New socks",\n      "price": 1.25\n    }\n  ]\n}'