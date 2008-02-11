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
    image.drawInRect_fromRect_operation_fraction(
      aRect,
      NSZeroRect,
      2,
      1.0)
  end

	def	mouseDown(event)
		self.dragFile_fromRect_slideBack_event(
				@rorGateController.gatePath, 
				self.frame,
				true,
				event)
	end
	
end
