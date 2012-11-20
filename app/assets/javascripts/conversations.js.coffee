# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
    # Scroll messages window to bottom as couldn't do it in css for now
  scrollConversationToBottom()

window.scrollConversationToBottom = ->
  msg_div = $('.conversation .messages')
  msg_div[0].scrollTop = msg_div[0].scrollHeight if msg_div.length > 0