var chai = require('chai')
  , sinonChai = require('sinon-chai');

process.env.NODE_ENV = process.env.NODE_ENV || 'test';

chai.should();
chai.use(sinonChai);
