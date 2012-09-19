$ ->
  Nreduce.Models.Startup = Backbone.Model.extend(
  
  )

  Nreduce.Collections.Startups = Backbone.Collection.extend(
    url: '/api/startups'

    # Needed for Supermodel
    model: (attrs, options) ->
      Nreduce.Models.Startup.create(attrs, options)

  )

  Nreduce.Models.Startup.has().many('team_members',
    collection: Nreduce.Models.Startup,
    inverse: 'startup'
  )

  _.extend(Nreduce.Models.Question, Nreduce.Mixins.Models)