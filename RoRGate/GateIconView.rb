#
#  GateIconView.rb
#  RoRGate
#
#  Created by Juan Germán Castañeda Echevarría on 2/9/08.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
include OSX

class GateIconView < NSImageView

	ib_outlet :rorGateController

  def drawRect(aRect)
    image = NSImage.alloc.initByReferencingFile(@rorGateController.rorAppIcon)
    if !image.isValid
      image = NSImage.imageNamed("NSApplicationIcon")
    end
    image.objc_send :drawInRect, aRect,
                    :fromRect, NSZeroRect,
                    :operation, 2,
                    :fraction, 1.0
    # setImageScaling(NSScaleProportionally)
    # setImageAlignment(NSImageAlignCenter)
  end

  def mouseDown(event)
    self.dragFile_fromRect_slideBack_event(
      @rorGateController.gatePath, 
      self.frame,
      true,
      event)
  end
end
