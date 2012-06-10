# custom code that adds progress:start and progress:stop behaviors to forms

$ = jQuery

# setup progress behaviors
$("form").live
  "progress:start": (e) ->
    form = $(this)

    progressClass = e.class || "in-progress"
    form.data("progress-class", progressClass)
    form.addClass(progressClass)

    btnSelector = e.btnSelector || ".btn.primary"
    form.data("btn-selector", btnSelector)
    primaryBtn = form.find(btnSelector)

    # try to find the label
    btnLabel = primaryBtn.text()
    btnLabel = primaryBtn.val() if btnLabel.length == 0

    # save the label
    primaryBtn.data("btn-label", btnLabel)

    # set progress label
    progressLabel = e.progressLabel || "Sending..."
    if primaryBtn.is("input")
      primaryBtn.val(progressLabel)
    else
      primaryBtn.text(progressLabel)

  "progress:stop": (e) ->
    form = $(this)

    # remove class
    form.removeClass(form.data("progress-class"))

    # change label back
    primaryBtn = form.find(form.data("btn-selector"))

    # restore the label
    btnLabel = primaryBtn.data("btn-label")
    if primaryBtn.is("input")
      primaryBtn.val(btnLabel)
    else
      primaryBtn.text(btnLabel)


