const logger = require('./logger');
// const underscore = require('underscore');
const _ = require('underscore');

logger.log("Hello World!");
// logger.logIt("Hello World again!");

var list = [1, 2, 3, 4, 5];
logger.log(_.first(list))