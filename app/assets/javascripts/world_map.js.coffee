# Requires raphael.js for drawing and countryData.js for shapes of all countries
class WorldMap
  @raph = null

  constructor: (@target, @points, @scale) ->
    @scale = @scale || 0.78
    @target = @target || 'world_map'

  initializeRaphael: ->
    return true if @raph?

    @raph = Raphael(@target, 1000 * @scale, 400 * @scale)

    @raph.setStart()
    for country of countryData.shapes
      @raph.path(countryData.shapes[country]).attr({
        stroke: if @scale < 0.5 then "none" else "#aaa"
        fill: "#fff"
        "stroke-opacity": 0.25
      })
    world = @raph.setFinish()
    world.scale(@scale, @scale, 0, 0)

  render: ->
    @initializeRaphael()
    for p in @points
      @renderPoint(p)

  # You have to call @renderMap() first to define @raphael.
  renderPoint: (point) ->
    attr = @getXY(point.lat, point.lng)
    radius = if @scale > 0.5 then 5 else 3
    fill = '#000'
    opacity = 0.8
    # dot = @raphael.circle().attr({fill: "r#FE7727:50-#F57124:100", stroke: "#fff", "stroke-width": 2, r: 0})
    dot = @raph.circle().attr({fill: fill, "stroke-width": 0, r: radius, opacity: opacity})
    dot.stop().attr(attr)

    # # Transparent dot for better popover mouseover behavior
    # transparentDot = @raphael.circle().attr({cx: attr.cx, cy: attr.cy, r: 30, fill: "#ffffff", 'fill-opacity': 0}).stop()

    # texty = attr.cy + (if attr.cy > 400 * @scale * .5 then 10 else -10)
    # @raphael.text(attr.cx, texty, point.get('content')).attr({
    #   fill: "#000"
    #   'font-size': '13'
    #   'font-weight': 'bold'
    #   'font-family': 'Helvetica, Arial, sans-serif'
    # })
    if @scale > 0.5
      popoverView = new DExp.Views.Popover({el: dot.node, model: point, radius: radius})
      popoverView.render()
    else if point.startup and @scale <= 0.5
      $(dot.node).tooltip({
        title: 'You'
        placement: if attr.cy < 400 * @scale * 0.5 then 'bottom' else 'top'
        trigger: 'manual'
        manualleft: radius + 1
        manualtop: if attr.cy < 400 * @scale * 0.5 then radius + 4 else 0
      })
      $(dot.node).tooltip('show')

  getXY: (lat, lon) ->
    cx: (lon * 2.6938 + 465.4) * @scale
    cy: (lat * -2.6938 + 227.066) * @scale