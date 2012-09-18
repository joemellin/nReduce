$ ->
  Nreduce.Views.Questions = Backbone.View.extend(
    el: '#app #questions'
    className: 'questions'
    template: JST['backbone/templates/questions']
    events:
      'click a#load_questions': 'loadQuestions'

    initialize: (options = {}) ->
      # bind 'this' context
      _.bindAll(@, 'render', 'loadQuestions', 'addQuestion')

      # Initialize collection
      @collection = new Nreduce.Collections.Questions()
      @collection.view = @
      @render()

    addQuestion: (question) ->
      $(@el, 'ul').append(JST['backbone/templates/question'](question: question))

    removeQuestion: (question_id) ->
      $("question_#{question_id}").remove()

    loadQuestions: ->
      @collection.fetch()

    render: ->
      questions = if @collection? then @collection.models else []
      @.$el.html(@template(questions: questions))
  )