$ ->
 # Add character counter to bio
  $('textarea.bio').each((i, element) ->
    $(element).textareaCount({minCharacterSize: 100, displayFormat: '#input characters'})
  )