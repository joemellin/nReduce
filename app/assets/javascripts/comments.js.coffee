# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  addCommentControlsListeners()
  $('#comments form textarea').autoResize(
    extraSpace: 3
  )

window.addCommentControlsListeners = ->
  $('.comment').bind 'mouseenter', ->
    $(this).find('.controls').show()
  $('.comment').bind 'mouseleave', ->
    $(this).find('.controls').hide()