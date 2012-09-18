$ ->
  Nreduce.Models.User = Backbone.Model.extend(
    defaults:
      roles: []

    is_entrepreneur: ->
      _.include(@roles, 'entrepeneur')

    is_investor: ->
      _.include(@roles, 'inevestor')

    is_mentor: ->
      _.include(@roles, 'mentor')

    # Returns the errors for a given field name
    errors_on: (field) ->
      if @get('errors')?
        @get('errors')['field']
      else
        null
  )

  Nreduce.Collections.Users = Backbone.Collection.extend(
    model: Nreduce.Models.User

    url: '/api/users'

  )