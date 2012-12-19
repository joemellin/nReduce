# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  $('select.num').change ->
    val = $(this).val()
    url = "/requests/new?num=#{val}"
    tweet_url = $('#request_data_0').val()
    url += "&tweet_url=#{encodeURIComponent(tweet_url)}" if tweet_url?
    window.location = url

  $('.requests textarea').autosize()