'use strict'

var log = require('npmlog')
var path = require('path')
var Promise = require('promise')
var fs = require('vigour-fs/lib/server')
var mkdirp = Promise.denodeify(fs.mkdirp)

module.exports = exports = function () {
  log.info('- creating folder for chromecast web-')
  return mkdirp(this.buildDir)
}