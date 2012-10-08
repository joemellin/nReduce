# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->

  # iPhone-style checkboxes: http://awardwinningfjords.com/2009/06/16/iphone-style-checkboxes.html
  $('form.startup .investable, form.startup .mentorable').iphoneStyle(
    checkedLabel: 'YES',
    uncheckedLabel: 'NO',
    onChange: ->
      $('form.startup').submit()
    # onChange: ->
    #   $('form.startup').submit()
    #   if $('#startup_investable').attr('checked') == 'checked'
    #     $('.investor_profile').fadeIn()
    #     $('.investor_profile_inactive').fadeOut()
    #   else
    #     $('.investor_profile').fadeOut()
    #     $('.investor_profile_inactive').fadeIn()
  )

  # Screenshot carousel - set long interval between auto-change
  $('#screenshots_carousel').carousel({ interval: 100000 })

  $('.screenshot.screenshot_modal').click ->
    # Show modal if not visible
    if $('#screenshot_modal :visible').length == 0
      $('#screenshots_modal').modal()
    $('#screenshots_carousel').carousel($(this).data('id'))

  addButtonSelectHandlers = (button_klass) ->
    $(button_klass).click ->
      # Store value in hidden field
      $("#{button_klass}_hidden_field").val($(this).attr('rel'))
      # Highlight this button
      $(button_klass).removeClass('btn-primary')
      $(this).addClass('btn-primary') unless $(this).hasClass('disabled') # don't allow people to click if weakest element hasn't been selected yet

  # Turn weakest element and contact in to buttons, and change color when selected
  for button_klass in ['.weakest_element', '.contact_in']
    $(button_klass).button()
    addButtonSelectHandlers(button_klass) # need closure

  # Enable contact in once weakest element is selected
  $('.weakest_element').click ->
    $('.contact_in').removeClass('disabled')

  # Enable form once weakest element is selected
  $('.contact_in').click (e) ->
    if $(this).hasClass('disabled')
      e.preventDefault()
      e.stopPropagation()
    else
      $('.rating :submit').removeClass('disabled').removeAttr('disabled')

  # Prevent remote form from submitting so we can append success message  
  $('.ssss form[data-remote=true]').submit (e) ->
    e.stopPropagation()
    e.preventDefault()
    submit = $($(this).find(':submit'))
    $.ajax(
      type: 'PUT',
      url: $(this).attr('action'),
      data: $(this).seri
      success: (data) ->
        if $('.saved').length == 0
          submit.after('<span style="font-weight: bold; padding-left: 10px;" class="saved">Saved!</span>')
          setTimeout( ->
            $('.saved').remove()
          , 5000)
    )