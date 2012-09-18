$ ->
  Nreduce.Models.Question = Backbone.Model.extend(
    defaults:
      content: 'New Question'
  )

  Nreduce.Collections.Questions = Backbone.Collection.extend(
    model: Nreduce.Models.Question

    url: '/api/questions'

    initialize: ->
      _.bindAll(@, 'renderAll')
      @bind('reset', @renderAll)

    renderAll: ->
      @view.render()
  )