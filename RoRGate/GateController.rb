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

	ib_outlet :webView, :mainWindow
	attr_accessor :rorApp, :name, :port, :appURL, :appPath

	def awakeFromNib()
		getPreferences()
		runRoRApp()
		@webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@appURL)))
	end

	def	getPreferences()
		prefsPlist = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("prefs.plist")
		@prefs = NSDictionary.dictionaryWithContentsOfFile(prefsPlist)		
		
		@name = @prefs.valueForKey("name")
		@port = @prefs.valueForKey("port")
		@appURL = "http://0.0.0.0:" + @port
		@appPath = @prefs.valueForKey("path")
		@allIncPkg = @prefs.valueForKey("allIncPkg")
		
		@mainWindow.setTitle(@name)
	end

	def	runRoRApp()
	  if @allIncPkg == 1
	    launchPath = NSBundle.mainBundle.pathForResource_ofType("rorApp",nil)
    else
      launchPath = @appPath.stringByAppendingPathComponent("script/server")
	  end
		@rorApp = NSTask.alloc.init
		@rorApp.setLaunchPath(launchPath)
		@rorApp.setCurrentDirectoryPath(@appPath)
		@rorApp.setArguments(NSArray.arrayWithObjects("--port", @port, nil))
		@rorApp.launch
	end
	
	def webView_didFailProvisionalLoadWithError_forFrame(sender, error, frame)
		@webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@appURL)))
	end
	
	def applicationShouldTerminate(sender)
		@rorApp.terminate()
		true
	end
	
end
