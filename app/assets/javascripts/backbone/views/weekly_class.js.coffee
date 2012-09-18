$ ->
  Nreduce.Views.WeeklyClass = Backbone.View.extend(
    el: '#app #weekly_class'
    className: 'weekly_classes'
    template: JST['backbone/templates/weekly_class']

    initialize: (options = {}) ->
      # bind 'this' context
      _.bindAll(@, 'render')

      # Initialize model
      @model.view = @ if @model?

      @questionView = new Nreduce.Views.Questions()
      
      @render()

    render: ->
      @.$el.html(@template(weekly_class: @model))
  )