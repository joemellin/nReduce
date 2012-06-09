#= require "./vendor/firebugx.js"
#= require "./vendor/json2.js"
#= require "./vendor/browser-detect.js"
#= require "./vendor/jquery-1.7.1.js"
#= require "./vendor/jquery.utils.js"
#= require "./vendor/jquery.plugins/form.progress.js"
#= require "./vendor/jquery.plugins/jquery.ata.js"
#= require "./vendor/jquery.plugins/jquery.scrollTo.js"
#= require "./vendor/jquery.plugins/jquery.autoellipsis.js"
#= require "./vendor/jquery.plugins/jquery.fixed.js"
#= require "./vendor/jquery.plugins/jquery.hotkeys.js"
#= require "./vendor/jquery.plugins/jquery.cookie.js"
#= require "./vendor/jquery.plugins/jquery.hoverintent.js"
#= require "./vendor/jquery.plugins/jquery.example.js"
#= require "./vendor/rails.js"
#= require "./vendor/underscore.js"
#= require "./vendor/underscore.strings.js"
#= require "./vendor/underscore.utils.js"
#= require "./vendor/bootstrap"
#= require "./vendor/jquery.isotope.min.js"

window.isSpeechCapable = ->
  elem = document.createElement('input')
  support = `'onwebkitspeechchange' in elem || 'speech' in elem`
  return support
