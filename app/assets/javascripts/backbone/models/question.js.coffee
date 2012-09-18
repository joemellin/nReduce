$ ->
  Nreduce.Question = Backbone.Model.extend(
    defaults:
      content: 'New Question'
  )

  Nreduce.QuestionList = Backbone.Collection.extend(
    model: Nreduce.Question

    url: '/api/questions'

    initialize: ->
      _.bindAll(@, 'renderAll')
      @bind('reset', @renderAll)

    renderAll: ->
      app.questionView.render()
  )