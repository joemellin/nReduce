
$ ->
  $('form.startup textarea').autosize()

  availableTags = [
    "ActionScript",
    "AppleScript",
    "Asp",
    "BASIC",
    "C",
    "C++",
    "Clojure",
    "COBOL",
    "ColdFusion",
    "Erlang",
    "Fortran",
    "Groovy",
    "Haskell",
    "Java",
    "JavaScript",
    "Lisp",
    "Perl",
    "PHP",
    "Python",
    "Ruby",
    "Scala",
    "Scheme"
  ]
  split = (val) ->
    return val.split( /,\s*/ )

  extractLast = (term) ->
    return split( term ).pop()

  $(".industry_list")
    # don't navigate away from the field on tab when selecting an item
    .bind("keydown", (event) ->
      if (event.keyCode == $.ui.keyCode.TAB && $(this).data("autocomplete").menu.active)
        event.preventDefault()
    )
    .autocomplete(
      minLength: 0,
      source: (request, response) ->
        # delegate back to autocomplete, but extract the last term
        response($.ui.autocomplete.filter(availableTags, extractLast(request.term)))
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