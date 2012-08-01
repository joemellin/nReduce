# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->

  # iPhone-style checkboxes: http://awardwinningfjords.com/2009/06/16/iphone-style-checkboxes.html
  $('form.startup .investable').iphoneStyle(
    checkedLabel: 'YES',
    uncheckedLabel: 'NO'
  );

  # Screenshot carousel
  $('#screenshots_carousel').carousel()
  
  # Prevent remote form from submitting so we can append success message  
  $('.investors form[data-remote=true]').submit (e) ->
    e.stopPropagation()
    e.preventDefault()
    submit = $($(this).find(':submit'))
    $.ajax(
      type: $(this).attr('method').toUpperCase(),
      url: $(this).attr('action'),
      success: (data) ->
        submit.after('<span style="font-weight: bold; padding-left: 10px;" class="saved">Saved!</span>')
        setTimeout(10000, ->
          $('.saved').hide()
        )
    )