$ ->
  Nreduce.Models.WeeklyClass = Backbone.Model.extend(

  )

  Nreduce.Collections.WeeklyClasses = Backbone.Collection.extend(
    url: '/api/weekly_classes'

      # Needed for Supermodel
    model: (attrs, options) ->
      Nreduce.Models.WeeklyClass.create(attrs, options)

  )

  Nreduce.Models.WeeklyClass.has().many('users',
    collection: Nreduce.Models.User,
    inverse: 'weekly_class'
  )

  _.extend(Nreduce.Models.WeeklyClass, Nreduce.Mixins.Models)