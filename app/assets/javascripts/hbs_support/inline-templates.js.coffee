# console.log("handlebars inline templates")

# wire up templates
window.JST ||= {}
window.JST.inline ||= {}

$ = jQuery
$(document).ready ->
  $("script[type='text/x-handlebars-template']").each ->
    self = $(this)
    templateName = self.data("template")
    console.log("Compiling: #{templateName}")
    window.JST.inline[templateName] = Handlebars.compile(self.html())

