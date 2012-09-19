Nreduce.Mixins.Models = {
  # Returns the errors for a given field name
  errors_on: (field) ->
    if @get('errors')?
      @get('errors')['field']
    else
      null
}