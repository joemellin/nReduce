$ ->
  # Toggle visibility of sign in / sign up forms
  $('.sign_in_toggle').click ->
    $(this).hide()
    console.log 'here'
    $('.sign_up_toggle, #sign_in').show()
    $('#sign_up').hide()
    console.log 'here2'

  $('.sign_up_toggle').click ->
    $(this).hide()
    $('.sign_in_toggle, #sign_up').show()
    $('#sign_in').hide()

  #$('.profile_completeness .well').tooltip({placement: 'left'})
  $('form.user textarea').autosize()

  $('.invite_team_modal').click ->
    $('#invite_team_modal').modal()

  $('.nstar_banner .clickable').click ->
    window.location = '/nstar';

  $('.external').click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $('#ciao').modal()
    $('#ciao_link').attr('href', $(this).attr('href'))

  $('#ciao_link').click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $('#ciao').modal('hide')
    window.open($(this).attr('href'), '_blank')

  $('.user_add_teammate_btn').click (e) ->
    e.preventDefault()
    addTeammateButton('user')

  $('.startup_add_teammate_btn').click (e) ->
    e.preventDefault()
    addTeammateButton('startup')

  # Show arrow when scrolling down page
  $(window).bind 'scroll', ->
    scroll_at = $(this).scrollTop()
    if scroll_at < 20
      $('.arrow').css({'opacity': 1})
    else if scroll_at < 200
      opacity = 1 / ((scroll_at - 20) / 100.0)
      $('.arrow').css({'opacity': opacity})
    else
      $('.arrow').css({'opacity': 0})

  $('.notifications li.item, .conversations li.item').click ->
    window.location = $(this).attr('rel') if $(this).attr('rel')?

  # Mark notifications as read after clicking on menu item
  $('.notifications .dropdown-toggle').click ->
    if parseInt($(this).attr('rel')) != 0
      $.post('/notifications/mark_all_as_read', ->
        $('.notifications .dropdown-toggle .icon').addClass('down')
        $('.notifications .dropdown-toggle .icon').attr('rel', 'up')
        $('.notifications .dropdown-toggle .badge').hide()
      )


  # mark messages as seen
  $('.conversations .dropdown-toggle').click ->
    if parseInt($(this).attr('rel')) != 0
      $.post('/messages/mark_all_as_seen', ->
        $('.conversation .dropdown-toggle .icon').addClass('down')
        $('.conversations .dropdown-toggle .icon').attr('rel', 'up')
        $('.conversations .dropdown-toggle .badge').hide()
      )

  $('.relationship_requests .dropdown-toggle').click ->
    if parseInt($(this).attr('rel')) != 0
      $.post('/relationships/mark_all_as_seen', ->
        $('.relationship_requests .dropdown-toggle .icon').addClass('down')
        $('.relationship_requests .dropdown-toggle .icon').attr('rel', 'up')
        $('.relationship_requests .dropdown-toggle .badge').hide()
      )


  $('.notifications .dropdown-toggle .icon, .relationship_requests .dropdown-toggle .icon, .conversations .dropdown-toggle .icon').mouseover ->
    if $(this).hasClass('new') || $(this).attr('rel') == 'new'
      rel = 'new'
      $(this).addClass('down').removeClass('up')
    else
      rel = 'up'
    $(this).attr('rel', rel)
    $(this).addClass('down').removeClass(rel)


  $('.notifications .dropdown-toggle .icon, .relationship_requests .dropdown-toggle .icon, .conversations .dropdown-toggle .icon').mouseout ->
    if $(this).hasClass('new') || $(this).attr('rel') == 'new'
      rel = 'new'
      $(this).addClass('down').removeClass('up')
    else
      rel = 'up'
    $(this).attr('rel', rel)
    $(this).addClass(rel).removeClass('down')
    
  # Type can be user or startup
  addTeammateButton = (type) ->
    random = Math.floor((Math.random()*1000000)+1);
    id = "teammate_email_#{random}"
    $('.teammates').append('<div class="email" id="' + id + '"><input type="text" name="' + type + '[teammate_emails][]" size="30" placeholder="founder@email.com" /> <a href="#" class="btn" onclick="$(\'#' + id + '\').remove(); return false;"><i class="icon-minus"></i></a></div>')


  last_startup_search = 0

  $('.startups-autocomplete').typeahead(
    minLength: 2
    source: (query, process) ->
      now = new Date()
      # Make sure we only search every two seconds
      if last_startup_search < (now.valueOf() - 2000)
        $.ajax(
          type: 'POST'
          url: '/startups/search'
          data: {query: query}
          dataType: 'json'
          success: (results) ->
            process(results)
        )
        now = new Date()
        last_startup_search = now.valueOf()
    matcher: (item) ->
      true
  )

  split = (val) ->
    return val.split( /,\s*/ )

  extractLast = (term) ->
    return split( term ).pop()

  initializeTagAutocomplete = (tag_context) ->
    $(".#{tag_context}_list_autocomplete")
      # don't navigate away from the field on tab when selecting an item
      .bind("keydown", (event) ->
        if (event.keyCode == $.ui.keyCode.TAB && $(this).data("autocomplete").menu.active)
          event.preventDefault()
      )
      .autocomplete(
        minLength: 0,
        source: (request, response) ->
          $.getJSON("/tags/#{tag_context}/", {term: extractLast(request.term)}, response)
        ,
        focus: () ->
          # prevent value inserted on focus
          false
        ,
        select: (event, ui) ->
          terms = split(this.value)
          # remove the current input
          terms.pop()
          # add the selected item
          terms.push(ui.item.value)
          # add placeholder to get the comma-and-space at the end
          terms.push("")
          this.value = terms.join(", ")
          false
      )

  # Autocomplete for tag fields
  for tag_context in ['industries', 'skills']
    initializeTagAutocomplete(tag_context)

  # Countdown code
  # much grateful thanks to the countdown code from http://mahamusicfestival.com/wp-content/themes/maha2012/js/maha.js
  oxide_countdown = ->
    d = new Array()
    h = new Array()
    m = new Array()
    s = new Array()
    go = 0
    countdown_element = $('#countdown');
    $dayspan = $(countdown_element).find('.days span')
    $hourspan = $(countdown_element).find('.hours span')
    $minutespan = $(countdown_element).find('.minutes span')
    $secondspan = $(countdown_element).find('.seconds span')

    $dayspan.each((i, e) ->
        n = parseFloat($(e).text())
        d.push(n);
        go = go + n
      )
    $hourspan.each((i, e) ->
      n = parseFloat($(e).text())
      h.push(n)
      go = go + n
    )
    $minutespan.each((i, e) ->
      n = parseFloat($(e).text())
      m.push(n)
      go = go + n
    )
    $secondspan.each((i, e) ->
      n = parseFloat($(e).text())
      s.push(n)
      go = go + n
    )
    # Preset the arrays in an expected failure condition
    di = d.length
    s[1]--
    if s[1] < 0
      # Underrun on seconds, take away one from tens of seconds!
      s[1] = 9
      s[0] = s[0] - 1
    if s[0] < 0
      # Underrun on tens of seconds, take away a minute!
      s[0] = 5
      m[1] = m[1] - 1
    if m[1] < 0 # min right
      m[1] = 9
      m[0] = m[0] - 1
    if m[0] < 0 # min left
      m[0] = 5
      h[1] = h[1] - 1 
    if h[1] < 0 # hour right
      h[1] = 9
      h[0] = h[0] - 1 
    if h[0] < 0
      h[0] = 2
      h[1] = 3
      d[di-1] = d[di-1] - 1
    while (di--)
      if (d[di] < 0)
        d[di] = 9
        if (di > 0)
          d[di - 1] = d[di - 1] - 1
    if go == 0
      clearInterval(timer)
    else
      $dayspan.each( (i, e) ->
        if parseFloat($(e).text()) != d[i]
          oxide_number_drop(e, d, i)
      )
      $hourspan.each( (i, e) ->
        if parseFloat($(e).text()) != h[i]
          oxide_number_drop(e, h, i)
      )
      $minutespan.each( (i, e) ->
        if parseFloat($(e).text()) != m[i]
          oxide_number_drop(e, m, i)
      )
      $secondspan.each( (i, e) ->
        if parseFloat($(e).text()) != s[i]
          oxide_number_drop(e, s, i)
      )

  oxide_number_drop = (elem, array, index) ->
    $(elem).stop(true).animate(
      'top': '80px'
    , 100, () -> 
      $(elem).css(
        'top': '-80px'
      ).text(array[index]).animate(
        'top': '0'
      , 100)
    )

  if $('#countdown').length > 0
    timer = setInterval(oxide_countdown, 1000);

