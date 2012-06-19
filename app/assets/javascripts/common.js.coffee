$ ->
  # Toggle visibility of sign in / sign up forms
  $('.sign_in_toggle').click ->
    $(this).hide()
    console.log 'here'
    $('.sign_up_toggle, #sign_in').show()
    $('#sign_up').hide()
    console.log 'here2'

  $('.sign_up_toggle').click ->
    $(this).hide()
    $('.sign_in_toggle, #sign_up').show()
    $('#sign_in').hide()