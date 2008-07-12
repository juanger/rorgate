#
#  GateController.rb
#  Gate
#
#  Created by Juan Germán Castañeda Echevarría on 2/8/08.
#  Copyright (c) 2008 Castech. All rights reserved.
#

require 'osx/cocoa'
include OSX
require_framework 'WebKit'

class GateController < OSX::NSObject

	ib_outlet  :gateMenu, :helpMenu, :devMenu
	ib_outlet  :server_hud, :server_out
	
	def awakeFromNib()
		getPreferences()
		if @dev == 1
		  configServerHUD()
	  else
      NSApp.mainMenu.removeItem @devMenu
	  end
		runRoRApp()
    setMenuItems()
	end
	
	def applicationShouldTerminate(sender)
	  stopRoRApp()
		true
	end
	
	def setMenuItems()
    @gateMenu.submenu().itemWithTag(1).setTitle("About " + @name)
    @gateMenu.submenu().itemWithTag(2).setTitle("Hide " + @name)
    @gateMenu.submenu().itemWithTag(3).setTitle("Quit " + @name)
    @helpMenu.submenu().itemWithTag(4).setTitle(@name + " Help")
  end

  ##
  #  Methods to Run RoR application 
  ##

  def getPreferences()
    prefsPlist = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("prefs.plist")
    @prefs = NSDictionary.dictionaryWithContentsOfFile(prefsPlist)  
    
    @name = @prefs[:name]
    @port = @prefs[:port]
    @appURL = "http://0.0.0.0:" + @port
    @appPath = @prefs[:path]
    @allIncPkg = @prefs[:allIncPkg]
    @dev = @prefs[:development]
    @icon = @prefs[:icon]
    # NSApp.setApplicationIconImage(
    #         NSImage.alloc.initWithContentsOfFile("#{NSBundle.mainBundle.resourcePath}/#{@icon}"))

    #NSWorkspace.sharedWorkspace.noteFileSystemChanged NSBundle.mainBundle.bundlePath
  end
     
  def runRoRApp()
    if @allIncPkg == 1
      launchPath = NSBundle.mainBundle.pathForResource_ofType("rorApp",nil) + "/script/server"
    else
      launchPath = @appPath.stringByAppendingPathComponent("script/server")
    end
    @rorApp = NSTask.alloc.init
    @rorApp.setLaunchPath(launchPath)
    @rorApp.setCurrentDirectoryPath(@appPath)
    @rorApp.setArguments(NSArray.arrayWithObjects("--port", @port, nil))
    if @dev == 1
      @rorApp.setStandardOutput(NSPipe.pipe)
      @rorApp.setStandardError(@rorApp.standardOutput)
      @rorApp.standardOutput.fileHandleForReading.readInBackgroundAndNotify
      nCenter = NSNotificationCenter.defaultCenter
      nCenter.objc_send :addObserver, self,
                :selector, 'gotData',
                :name, NSFileHandleReadCompletionNotification,
                :object, @rorApp.standardOutput.fileHandleForReading
    end
    @rorApp.launch
  end
	
	def stopRoRApp()
	 	@rorApp.terminate()
		NSNotificationCenter.defaultCenter.removeObserver self
	end
	
	##
	#  Server Output 
	##
	
	def gotData(aNotification)
	 data = aNotification.userInfo.objectForKey(NSFileHandleNotificationDataItem)
	 data_string = NSString.alloc.objc_send(:initWithData, data,
                            :encoding, NSUTF8StringEncoding).to_s
                            
	 if data.length != 0
	   @server_out.appendString(data_string)
   else
     stopRoRApp()
   end
   aNotification.object.readInBackgroundAndNotify
	end
	
	def configServerHUD()
    @server_out.setBackgroundColor NSColor.colorWithDeviceWhite_alpha(0.12,0.84)
    @server_out.setTextColor(NSColor.whiteColor)
    @server_out.setFont(NSFont.fontWithName_size('Monaco', 12.0))
  end
  
  ##
  #  Actions
  ##
  
	ib_action :server_display do |sender|
    @server_hud.display
	end
	
	ib_action :open_in_textmate do |sender|
	  if @allIncPkg != 1
	    appPath = @appPath 
    else
      appPath = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("rorApp")
    end
	  `open -a textmate "#{appPath}"`
	end
	
	ib_action :reset_server do |sender|
	  stopRoRApp()
	  runRoRApp()
	end
	
	
end

class NSTextView
  def appendString(str)
    len = self.textStorage.length
    replaceCharactersInRange_withString(NSMakeRange(len,0), str)
    scrollRangeToVisible(NSMakeRange(string.length, 0))    
  end
end