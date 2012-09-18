$ ->
  Nreduce.Routers.Application = Backbone.Router.extend(
    routes:
      '': 'index'

    index: ->
      @view = new Nreduce.Views.WeeklyClass()

  )
