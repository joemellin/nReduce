$ ->
  $('form.startup textarea, form.checkin textarea').autosize()
  $('a[rel=tooltip]').tooltip()
  $('form.checkin button.accomplished').click ->
    val = $(this).data('value')
    $('#checkin_accomplished').val(val)

  # if $('form.checkin').length > 0
  #   setTimeout( ->
  #     enableCheckinFormIfComplete(true)
  #   , 1000)

  $('.video_form .youtube_url').change( ->
    field = $(this)
    if field.length > 0 && field.val() != ''
      validateYoutubeForm(field)
  )

  $('form.startup .invites .startup_invite_btn').click( ->
    data = $('form.startup .invites .startup_invite').serializeArray()
    $.ajax(
      type: 'POST',
      url: "/startup/invite_ajax",
      data: data,
      dataType: 'script'
    )
    false
  )

  validateYoutubeForm = (element) ->
    video_id = element.data('video-id')
    url = element.val()
    return unless url? && url.length > 0
    if isValidYoutubeUrl(url)
      $("##{video_id} .video_type").val('Youtube')
      $("##{video_id} .completed").show()
      $("##{video_id} .current_video, ##{video_id} .instructions").hide()
    else
      $("##{video_id} .completed").hide()

  # if they choose to record again
  # $('.video_form .record_again').click ->
  #   video_id = $(this).data('video_id')
  #   $("##{video_id} .completed").show()
  #   $("##{video_id} .fields").hide()

  isValidYoutubeUrl = (string) ->
    # http://www.youtube.com/?watch?v=id
    return true if string.match(/^https?\:\/\/.*youtube\.com\/watch\?v\=.+$/)
    # http://www.youtu.be/?watch=id
    return true if string.match(/^https?\:\/\/.*youtu\.be\/.+$/)
    # http://www.youtube.com/embed/id
    return true if string.match(/^https?\:\/\/.*youtube\.com\/embed\/.+$/)
    false

  enableCheckinFormIfComplete = (add_timer = false) ->
    type = $('#checkin_type').val()
    is_complete = false
    validateYoutubeForm($('.video_form .youtube_url'))
    if type == 'before'
      is_complete = true if ($('.video_form .completed:visible').length == 1 || $('.video_form .video_id').val()?)  && $('.checkin_start_focus').val().length > 0
    else if type == 'after'
      if ($('.video_form .completed:visible').length == 1 || $('.video_form .video_id').val()?) && $('#checkin_accomplish').val() != '' && $('.checkin_end_comments').val().length > 0
        # if launched they need a measurement
        if $('#startup_launched').val() == 'true' && $('#checkin_measurement_value').val() != ''
          is_complete = true
        # else no requirement
        else if $('#startup_launched').val() == 'false'
          is_complete = true
    if is_complete
      #console.log 'complete'
      $('form.checkin :submit').removeClass('disabled').removeAttr('disabled')
    else
      #console.log 'not complete'
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
    $("##{video_id} .youtube_url").val(''); # clear out youtube url
    

  