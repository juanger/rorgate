#
#  MyDocument.rb
#  RoRgate
#
#  Created by Juan Germ‡n Casta–eda Echevarr’a on 7/2/08.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#


require 'osx/cocoa'
include OSX
require_framework 'WebKit'

class MyDocument < OSX::NSDocument

  ib_outlets :webView, :mainWindow
  attr_reader :webView
  
  # def makeWindowControllers
  #   
  # end
  
  def windowNibName
    # Override returning the nib file name of the document If you need
    # to use a subclass of NSWindowController or if your document
    # supports multiple NSWindowControllers, you should remove this
    # method and override makeWindowControllers instead.
    return "MyDocument"
  end

  def windowControllerDidLoadNib(aController)
    super_windowControllerDidLoadNib(aController)
    # Add any code here that need to be executed once the
    # windowController has loaded the document's window.
    getPreferences()
    @webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@appURL)))
    @webView.setUIDelegate self  
  end

  def dataRepresentationOfType(aType)
    # Insert code here to write your document from the given data.
    # You can also choose to override
    # fileWrapperRepresentationOfType or writeToFile_ofType
    # instead.
    return nil
  end

  def loadDataRepresentation_ofType(data, aType)
    # Insert code here to read your document from the given data.  You
    # can also choose to override
    # loadFileWrapperRepresentation_ofType or readFromFile_ofType
    # instead.
    return true
  end
  
  def	getPreferences()
		prefsPlist = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("prefs.plist")
		@prefs = NSDictionary.dictionaryWithContentsOfFile(prefsPlist)

		@name = @prefs[:name]
		@port = @prefs[:port]
		@appURL = "http://0.0.0.0:#{@port}"
		@mainWindow.setTitle(@name)
	end
	
	
  def isDocumentEdited
    false
  end
  
  ##
  #  Web Kit
  ##
  
  def webView_createWebViewWithRequest(webView, request)
    myDocument = NSDocumentController.sharedDocumentController.openUntitledDocumentOfType_display("DocumentType", true)
    myDocument.webView.mainFrame.loadRequest(request)
    myDocument.webView
  end
  
  def webViewShow(sender)
    myDocument = NSDocumentController.sharedDocumentController.documentForWindow(sender.window)
    myDocument.showWindows
  end
  
  def webView_didFailProvisionalLoadWithError_forFrame(sender, error, frame)
		@webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@appURL)))
	end
  
end
