$ ->

  Nreduce.QuestionView = Backbone.View.extend(
    el: $('.app')

    events:
      'click a#load_questions': 'loadQuestions'

    template: JST['backbone/templates/questions']

    initialize: ->
      # bind 'this' context
      _.bindAll(@, 'render', 'loadQuestions')

      # Initialize collection
      @collection = new Nreduce.QuestionList()
      @render()
      
    addQuestion: ->
      $('ul', @el).append('<li>One more</li>')

    loadQuestions: ->
      app.questionList.fetch(
        success: ->
          app.questionView.render()
      )

    render: ->
      questions = if app.questionList? then app.questionList.models else []
      @.$el.html(@template(questions: questions))
  )  

  Nreduce.Router = Backbone.Router.extend(
    routes:
      '': 'dashboard',
      'startups/:id': 'showStartup'

    dashboard: ->
      @questionView = new Nreduce.QuestionView()
      @questionList = new Nreduce.QuestionList()
      #@questionList.fetch()

    showStartup: (id) ->
      console.log "show startup with id #{id}"
  )

  window.app = new Nreduce.Router()

  Backbone.history.start();