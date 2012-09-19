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
  )

  Nreduce.Collections.Users = Backbone.Collection.extend(
    url: '/api/users'

    # Needed for Supermodel
    model: (attrs, options) ->
      Nreduce.Models.User.create(attrs, options)

  )

  Nreduce.Models.User.has().many('questions',
    collection: Nreduce.Models.Question,
    inverse: 'user'
  )

  Nreduce.Models.User.has().one('weekly_class',
    collection: Nreduce.Models.WeeklyClass,
    inverse: 'users'
  )

  _.extend(Nreduce.Models.User, Nreduce.Mixins.Models)