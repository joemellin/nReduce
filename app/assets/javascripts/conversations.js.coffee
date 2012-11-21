# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  # Scroll messages window to bottom as couldn't do it in css for now
  scrollConversationToBottom()

  $('.conversation textarea').autosize()
  
window.scrollConversationToBottom = ->
  msg_div = $('.conversation .messages')
  msg_div[0].scrollTop = msg_div[0].scrollHeight + 10 if msg_div.length > 0


window.initializeConversationAutocomplete = ->
  last_conversation_search = 0
  $('.conversation-to-autocomplete').typeahead(
    minLength: 2
    source: (query, process) ->
      now = new Date()
      # Make sure we only search every two seconds
      if last_conversation_search < (now.valueOf() - 1500)
        $.ajax(
          type: 'POST'
          url: '/messages/search_people_and_startups'
          data: {query: query}
          dataType: 'json'
          success: (results) ->
            process(results)
        )
        now = new Date()
        last_conversation_search = now.valueOf()
    matcher: (item) ->
      true
  )