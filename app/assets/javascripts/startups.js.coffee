$ ->
  $('form.startup textarea').autosize()
  $('a[rel=tooltip]').tooltip()

  $('form.checkin').submit (e) ->
    e.stopPropagation()
    e.preventDefault()
    $(this).find(':submit').attr('disabled', true)
    # Save video recording if it exists
    saveRecording()

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
    

  