$ ->
  Nreduce.Models.Question = Backbone.Model.extend(
    defaults:
      content: 'New Question'
  )

  Nreduce.Collections.Questions = Backbone.Collection.extend(
    url: '/api/questions'

    initialize: ->
      _.bindAll(@, 'renderAll')
      @bind('reset', @renderAll)

    renderAll: ->
      @view.render() if @view?

    # Needed for Supermodel
    model: (attrs, options) ->
      Nreduce.Models.Question.create(attrs, options)
  )

  Nreduce.Models.Question.has().one('user',
    model: User,
    inverse: 'questions'
  )

  _.extend(Nreduce.Models.Question, Nreduce.Mixins.Models)