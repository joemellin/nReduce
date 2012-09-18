$ ->
  Nreduce.Models.WeeklyClass = Backbone.Model.extend(

  )

  Nreduce.Collections.WeeklyClasses = Backbone.Collection.extend(
    model: Nreduce.Models.WeeklyClass

    url: '/api/weekly_classes'

  )