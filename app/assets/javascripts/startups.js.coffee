$ ->
  $('form.startup textarea, form.checkin textarea').autosize()
  $('a[rel=tooltip]').tooltip()

  if $('form.checkin').length > 0
    setTimeout( ->
      enableCheckinFormIfComplete(true)
    , 1000)

  enableCheckinFormIfComplete = (add_timer = false) ->
    type = $('#checkin_type').val()
    is_complete = false
    if type == 'before'
      is_complete = true if $('.video_form .completed:visible').length == 1 && $('.checkin_start_focus').val().length > 0
    else if type == 'after'
      is_complete = true if $('.video_form .completed:visible').length == 1 && $('.checkin_accomplished').is(':checked') && $('.checkin_end_comments').val().length > 0
    if is_complete
      console.log 'complete'
      $('form.checkin :submit').removeClass('disabled').removeAttr('disabled')
    else
      console.log 'not complete'
      $('form.checkin :submit').addClass('disabled').attr('disabled', true)
    if add_timer
      setTimeout( ->
        enableCheckinFormIfComplete(true)
      , 1000)

  # Logic for showing/hiding video embedding
  $('.video_embed_buttons .button').click (e) ->
    e.preventDefault()
    video_id = $(this).data('video-id')
    type = $(this).data('embed-class')
    $("##{video_id} .video_embed_buttons, .video_embed").hide()
    $("##{video_id} .video_embed_cancel").show()
    $("##{video_id} .#{type}").show()
    if type == 'screenr_embed'
      startRecording()

  $('.video_embed_cancel a').click (e) ->
    e.preventDefault()
    video_id = $(this).data('video-id')
    $("##{video_id} .video_embed_cancel, .video_embed").hide()
    $("##{video_id} .video_embed_buttons").show()
    

  