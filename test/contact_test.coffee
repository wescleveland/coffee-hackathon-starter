chai = require('chai')
should = chai.should()
app = require('../app')
Browser = require('zombie')
browser = new Browser({ site: 'http://localhost:3000' })


describe 'GET /contact', ->
  it 'should refuse partial form submissions', (done) ->
    browser.visit '/contact', ->
      browser
        .fill('name', 'Clementine')
        .fill('message', 'The Walking Dead')
        .pressButton 'Send', ->
          browser.success.should.be.true
          should.exist(browser.query('.alert-danger'))
          done()
