$ ->
  $('form.startup textarea, form.checkin textarea').autosize()
  $('a[rel=tooltip]').tooltip()
  $('form.checkin button.accomplished').click ->
    val = $(this).data('value')
    $('#checkin_accomplished').val(val)

  $('form.checkin button.checkin_day').click ->
    val = $(this).data('value')
    $('#checkin_day').val(val)

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

  showLargeSpinner = (element) ->
    opts = {
      lines: 11, # The number of lines to draw
      length: 11, # The length of each line
      width: 6, # The line thickness
      radius: 19, # The radius of the inner circle
      corners: 1, # Corner roundness (0..1)
      rotate: 0, # The rotation offset
      color: '#999', #rgb or #rrggbb
      speed: 1, # Rounds per second
      trail: 60, # Afterglow percentage
      shadow: false, # Whether to render a shadow
      hwaccel: false, # Whether to use hardware acceleration
      className: 'spinner', # The CSS class to assign to the spinner
      zIndex: 2e9, # The z-index (defaults to 2000000000)
      top: 'auto', # Top position relative to parent in px
      left: 'auto' # Left position relative to parent in px
    }
    spinner = new Spinner(opts).spin(element)

  $('.startup_spinner').each ->
    showLargeSpinner(this)

  showSmallSpinner = (element) ->
    opts = {
      lines: 11, # The number of lines to draw
      length: 3, # The length of each line
      width: 1, # The line thickness
      radius: 5, # The radius of the inner circle
      corners: 1, # Corner roundness (0..1)
      rotate: 0, # The rotation offset
      color: '#999', #rgb or #rrggbb
      speed: 1, # Rounds per second
      trail: 60, # Afterglow percentage
      shadow: false, # Whether to render a shadow
      hwaccel: false, # Whether to use hardware acceleration
      className: 'spinner', # The CSS class to assign to the spinner
      zIndex: 2e9, # The z-index (defaults to 2000000000)
      top: 'auto', # Top position relative to parent in px
      left: 'auto' # Left position relative to parent in px
    }
    spinner = new Spinner(opts).spin(element)

  $('.checkin .in_progress .box').each ->
    showSmallSpinner(this)

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
    

  