# App Initializer
#= require_self

# Backbone, Underscore & Rails Sync Lib
#= require ./lib/underscore-min
#= require ./lib/backbone-min
# require ./lib/backbone-rails-sync

# All Haml-Coffee Templates for Backbone (uses haml_coffee_assets gem)
#= require hamlcoffee
#= require_tree ./templates

# All App Files
#= require_tree ./models
#= require_tree ./views
#= require ./router

window.Nreduce =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

