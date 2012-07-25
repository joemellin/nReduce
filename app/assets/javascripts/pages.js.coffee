$ ->
  # SCROLLORAMA!
  # initialize the plugin, pass in the class selector for the sections of content (blocks)
  scrollorama = $.scrollorama
    blocks: '.scrollblock'
    enablePin: true

  # assign function to add behavior for onBlockChange event
  slideBackgrounds = $(".slide_bg")
  scrollorama.onBlockChange ->
    i = scrollorama.blockIndex
    currentBlock = scrollorama.settings.blocks.eq(i)
    currentBlockId = currentBlock.attr('id')

    # set console
    console.log('onBlockChange | blockIndex:'+i+' | current block: '+currentBlockId)

    currentBackground = currentBlock.find(".slide_bg")
    slideBackgrounds.filter(":visible").not(currentBackground).fadeOut("slow")
    currentBackground.not(":visible").fadeIn("slow")