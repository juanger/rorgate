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

	ib_outlet  :gateMenu, :helpMenu #:webView, :mainWindow
	#attr_accessor :rorApp, :name, :port, :appURL, :appPath

	def awakeFromNib()
		getPreferences()
		runRoRApp()
		#@webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@appURL)))
    setMenuItems()
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
    @rorApp.launch
  end
	
	def applicationShouldTerminate(sender)
		@rorApp.terminate()
		true
	end
	
end
