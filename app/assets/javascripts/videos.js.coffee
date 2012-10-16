# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


# Show Vimeo content onload
$ ->
  $('.js-vimeo').each( (i, elem) ->
    url = $(elem).data('url')

    response = $.ajax({
      url: 'https://vimeo.com/api/oembed.json'
      dataType: 'json'
      type: 'get'
      data: {
        url: url
        maxwidth: 570
        byline: false
        title: false
        portrait: false
        vimeo_logo: false
      }
      success: (response) =>
        $(elem).html(response.html)
      error: (e) =>
        console.log e
        $(elem).html('Could not load video. Please try again later.')
    })
  )

class window.VideoPlayer
  current_index: null

  # Videos should be array of JSON objects, each with a title and video_id attribute
  initialize = (@videos = [], @autoplay = false) ->
    # Add click listeners for other videos to be played
    vp = @
    $('.video_player .thumbnail').click =>
      vp.playVideo(vp.video_ids.indexOf($(this).data('video-id')))
    @playVideo(0) if @autoplay

  playVideo = (index) ->
    # stop and hide currently playing video
    if @current_index?
      current_video = $("##{@videos[current_index].video_id}")[0]
      if current_video?
        $f(iframe).api('pause')
        current_video.hide()
        $(".video_player .thumbnail[data-video-id=[#{@videos[current_index].video_id}]").removeClass('active')
      end
    end
    # Make sure video exists
    return unless @videos[index]?
    # get video iframe to be played
    video = @videos[index]
    iframe = $("##{id}")[0]
    player = $f(iframe)
    @current_index = index
    # show this video
    iframe.show()
    $(".video_player .thumbnail[data-video-id=[#{video.video_id}]").addClass('active')
    player.addEvent('ready', (id) ->
      player.addEvent('finish', =>
        @videoFinished(index)
      )
      $('.video_player .title').text(video.title) if video.title?
      # Start playing
      player.api('play')
    )

  videoFinished = (index) ->
    @playVideo(index + 1) if @autoplay


vimeo_ids = null

  # Will autoplay the vimeo videos that are embedded
window.vimeoAutoplayVideos = (iframe_ids = []) ->
  vimeo_ids = iframe_ids
  vimeoStartPlayer(vimeo_ids[0])

# This assumes video has already loaded
window.vimeoStartPlayer = (id) ->
  # Add listeners for the first video to play the next one
  iframe = $("##{id}")[0]
  player = $f(iframe)
  player.addEvent('ready', (id) ->
    player.addEvent('finish', vimeoVideoFinished)
    # Start playing the first video
    player.api('play')
  )

window.vimeoVideoFinished = (id) ->
  current_index = vimeo_ids.indexOf(id)
  return false if current_index == -1 || !vimeo_ids[current_index + 1]?
  # hide this player
  $("##{id}").hide()
  # play next video
  next_video_id = vimeo_ids[current_index + 1]
  $("##{next_video_id}").parent().show()
  vimeoStartPlayer(next_video_id)