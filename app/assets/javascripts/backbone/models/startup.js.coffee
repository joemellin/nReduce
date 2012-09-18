$ ->
  Nreduce.Models.Startup = Backbone.Model.extend(
  
  )

  Nreduce.Collections.Startups = Backbone.Collection.extend(
    model: Nreduce.Models.Startup

    url: '/api/startups'

  )