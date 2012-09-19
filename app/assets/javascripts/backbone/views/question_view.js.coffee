$ ->
  Nreduce.Views.Questions = Backbone.View.extend(
    el: '#app #questions'
    className: 'questions'
    template: JST['backbone/templates/questions/list']
    events:
      'click a#reload_questions': 'loadQuestions'

    initialize: ->
      # bind 'this' context
      _.bindAll(@, 'render', 'loadQuestions', 'addQuestion')

      # Initialize collection
      @collection.view = @ if @collection?
      #@render()

    addQuestion: (question) ->
      $(@el, 'ul').append(@template(question: question))

    removeQuestion: (question_id) ->
      $("question_#{question_id}").remove()

    loadQuestions: ->
      @collection.fetch()

    render: ->
      questions = if @collection? then @collection.models else []
      $('#question_count').text(questions.length)
      @.$el.html(@template(questions: questions))
  )
