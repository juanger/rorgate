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

  ib_outlets :webView, :progress, :url, :reload, :inspect
  attr_reader :webView, :title
  
  def windowNibName
    return "MyDocument"
  end

  def windowControllerDidLoadNib(aController)
    super_windowControllerDidLoadNib(aController)
    
    getPreferences()
    @webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@appURL)))
    @url.stringValue = @appURL
    @webView.setUIDelegate self 
    setup_toolbar
  end

  def dataRepresentationOfType(aType)
    return nil
  end

  def loadDataRepresentation_ofType(data, aType)
    return true
  end
  
  def getPreferences()
    prefsPlist = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("prefs.plist")
    @prefs = NSDictionary.dictionaryWithContentsOfFile(prefsPlist)

    @name = @prefs[:name]
    @port = @prefs[:port]
    @appURL = "http://0.0.0.0:#{@port}"
    #@mainWindow.setTitle(@name)
  end

  def isDocumentEdited
    false
  end
  
  # UI delegate
  
  def webView_createWebViewWithRequest(webView, request)
    myDocument = NSDocumentController.sharedDocumentController.openUntitledDocumentOfType_display("DocumentType", true)
    myDocument.webView.mainFrame.loadRequest(request)
    myDocument.webView
  end
  
  def webViewShow(sender)
    myDocument = NSDocumentController.sharedDocumentController.documentForWindow(sender.window)
    myDocument.showWindows
  end
  
  # Frame Load delegate
  
  def webView_didStartProvisionalLoadForFrame(sender, frame)
    # Only report feedback for the main frame.
    if frame == sender.mainFrame then
      @webView.window.setTitle("Loading...")
      @progress.startAnimation(self)
    end
  end
  
  def webView_didFinishLoadForFrame(sender, frame)
    @progress.stopAnimation(self)
  end
  
  def webView_didFailProvisionalLoadWithError_forFrame(sender, error, frame)
    @webView.mainFrame.loadRequest(
        NSURLRequest.objc_send(:requestWithURL, (NSURL.URLWithString(@appURL)),
                               :cachePolicy, NSURLRequestReloadIgnoringLocalCacheData,
                               :timeoutInterval, 30))
  end
  
  def webView_didReceiveTitle_forFrame(sender, title, frame)
    # Only report feedback for the main frame.
    if frame == sender.mainFrame then
      @webView.window.setTitle(title)
    end
  end

  # Resource delegate

  def webView_resource_willSendRequest_redirectResponse_fromDataSource(sndr, id, req, res, dataSrc) 
    new_request = req.mutableCopyWithZone(nil)
    new_request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData
    new_request
  end
  
  #  Toolbar
  
  def setup_toolbar
    @toolbar = NSToolbar.alloc.initWithIdentifier "WebToolbar"
    @toolbar.displayMode = NSToolbarDisplayModeIconOnly
    @toolbar.showsBaselineSeparator = false
    @toolbar.delegate = self
    @webView.window.setToolbar @toolbar
  end
  
  def toolbar_itemForItemIdentifier_willBeInsertedIntoToolbar(toolbar, itemIdent, willBeInserted)
    case itemIdent
    when "URL"
      item = NSToolbarItem.alloc.initWithItemIdentifier(itemIdent)
      item.target = self
      item.view = @url
      item.action = "load_url"
    when "Reload"
      item = NSToolbarItem.alloc.initWithItemIdentifier(itemIdent)
      item.target = self
      item.view = @reload
      item.action = "load_url"
    when "Inspect"
      item = NSToolbarItem.alloc.initWithItemIdentifier(itemIdent)
      item.target = self
      item.view = @inspect
      item.action = "inspect"
    end
    item
  end

  def toolbarDefaultItemIdentifiers(toolbar)
    [ "Reload", "URL",
      NSToolbarFlexibleSpaceItemIdentifier, "Inspect"]
  end
  
  def toolbarAllowedItemIdentifiers(toolbar)
    ["Reload", "URL", NSToolbarFlexibleSpaceItemIdentifier, "Inspect"]
  end
  
  ib_action :load_url do |sender|
    @webView.mainFrame.loadRequest(
        NSURLRequest.objc_send(:requestWithURL, (NSURL.URLWithString(@url.stringValue)),
                               :cachePolicy, NSURLRequestReloadIgnoringLocalCacheData,
                               :timeoutInterval, 30))
  end
  
  ib_action :inspect do |sender|
    @webView.inspector.show(sender)
  end
  
  ib_action :go_home do |sender|
    @webView.mainFrame.loadRequest(
        NSURLRequest.objc_send(:requestWithURL, (NSURL.URLWithString(@appURL)),
                               :cachePolicy, NSURLRequestReloadIgnoringLocalCacheData,
                               :timeoutInterval, 30))
  end
  
end
