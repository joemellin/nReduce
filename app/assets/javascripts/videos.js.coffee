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
