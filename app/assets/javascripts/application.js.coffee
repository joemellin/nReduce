$ = jQuery
$(document).on
  ready: ->
    # global styles go
    $(".alert").alert()

    if Settings.client.grid_debug
      $("body").bind "keydown", "esc", ->
        $("body").toggleClass("grid-debug")
        return true

