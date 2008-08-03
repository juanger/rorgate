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

FileManager = NSFileManager.defaultManager
RSRC_PATH = NSBundle.mainBundle.resourcePath
BNDL_PATH = NSBundle.mainBundle.bundlePath

class GateController < OSX::NSObject

  ib_outlet  :gateMenu, :helpMenu, :devMenu
  ib_outlet  :server_hud, :server_out
  ib_outlet  :pref_window, :pref_name, :pref_port, :pref_icon

  def initialize()
    # Inspector!!
    defaults = NSUserDefaults.standardUserDefaults
    appDefaults = {:WebKitDeveloperExtras => true}
    defaults.registerDefaults appDefaults
    @environment = "development"
    @server = ""
  end

  def awakeFromNib()
    getPreferences()
    if @dev == 1
      configServerHUD()
    else
      NSApp.mainMenu.removeItem @devMenu
    end
    pipe_log() if @dev == 1
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
  #  Methods to Run RoR application (fold)
  ##

  def setPaths()
    
  end

  def getPreferences()
    prefsPlist = File.join(RSRC_PATH,"prefs.plist")
    @prefs = NSDictionary.dictionaryWithContentsOfFile(prefsPlist)  

    @name = @prefs[:name]
    @port = @prefs[:port]
    @appURL = "http://0.0.0.0:" + @port
    @appPath = @prefs[:path]
    @allIncPkg = @prefs[:allIncPkg]
    @dev = @prefs[:development]
    @icon = @prefs[:icon]
  end

  def runRoRApp()
    if @allIncPkg == 1
      launchPath = File.join(RSRC_PATH, "rorApp", "script", "server")
    else
      launchPath = File.join(@appPath, "script", "server")
    end
    @rorApp = NSTask.alloc.init
    @rorApp.setLaunchPath(launchPath)
    @rorApp.setCurrentDirectoryPath(@appPath)
    @rorApp.setArguments([@server, "-e", @environment, "--port",@port])
    @rorApp.launch
  end

  def stopRoRApp()
    @rorApp.terminate()
    NSNotificationCenter.defaultCenter.removeObserver self
  end

  # (end)
  
  ##
  #  Server Output (fold)
  ##

  def pipe_log
    tail = NSTask.alloc.init
    tail.setLaunchPath("/usr/bin/tail")
    log = File.join(@appPath, "log", "#{@environment}.log")
    tail.setArguments(["-f", "-c", "0", log])
    pipe = NSPipe.pipe
    tail.standardOutput = pipe
    #tail.standardError = pipe
    pipe.fileHandleForReading.readInBackgroundAndNotify
    nCenter = NSNotificationCenter.defaultCenter
    nCenter.objc_send :addObserver, self,
                      :selector, 'gotData',
                      :name, NSFileHandleReadCompletionNotification,
                      :object, pipe.fileHandleForReading
    tail.launch
  end

  def gotData(aNotification)
    data = aNotification.userInfo.objectForKey(
      NSFileHandleNotificationDataItem)

    if data.length != 0
      data_string = NSString.alloc.objc_send(
          :initWithData, data,
          :encoding, NSUTF8StringEncoding).to_s
      @server_out.appendString(data_string)
      #@rorApp.standardOutput.fileHandleForReading.readInBackgroundAndNotify
    else
      stopRoRApp()
    end
    aNotification.object.readInBackgroundAndNotify
  end

  def configServerHUD()
    @server_out.setBackgroundColor(
        NSColor.colorWithDeviceWhite_alpha(0.12,0.84))
    @server_out.setTextColor(NSColor.whiteColor)
    @server_out.setFont(NSFont.fontWithName_size('Monaco', 12.0))
  end

  # (end)
  
  ##
  #  Actions (fold)
  ##
  
  ib_action :change_env do |sender|
    @environment = sender.title.downcase
    stopRoRApp()
    runRoRApp()
    sender.menu.itemArray.each { |item| item.state = NSOffState}
    sender.state = NSOnState
  end
  

  ib_action :reset_server do |sender|
    stopRoRApp()
    runRoRApp()
  end

  ib_action :open_in_textmate do |sender|
    if @allIncPkg != 1
      appPath = @appPath 
    else
      appPath = File.join(RSRC_PATH, "rorApp")
    end
    `open -a textmate "#{appPath}"`
  end

  ib_action :open_in_terminal do |sender|
    if @allIncPkg == 1
      app_path = File.join(RSRC_PATH, "rorApp")
    else
      app_path = @appPath
    end
    command = %(do script with command \"cd \" & \"#{app_path}\")
    `osascript -e 'tell application \"Terminal\" to #{command}'`
    `osascript -e 'tell application \"Terminal\" to activate'`
  end

  ib_action :select_icon do |sender|
    oPanel = NSOpenPanel.openPanel
    oPanel.setCanChooseFiles true
    oPanel.setCanChooseDirectories false

    fileTypes = ["icns", "png", "jpg"]
    result = oPanel.runModalForDirectory_file_types(
        NSHomeDirectory(), nil, fileTypes)

    if result == NSOKButton
      @tmp_icon_path = oPanel.filenames.objectAtIndex 0
      @pref_icon.setImage(
          NSImage.alloc.initWithContentsOfFile(@tmp_icon_path))
    end
  end

  ib_action :save_preferences do |sender|
    prefs = { :name => @pref_name.stringValue.strip,
      :port => @pref_port.stringValue.strip,
      :icon => @icon,
      :path => @appPath,
      :allIncPkg => @allIncPkg,
      :development => @dev,
    }
    
    # New Icon
    if  !@tmp_icon_path.nil? &&
        @icon != @tmp_icon_path.lastPathComponent()
      icon_path = File.join(RSRC_PATH, @tmp_icon_path.lastPathComponent())
      FileManager.removeFileAtPath_handler(RSRC_PATH + "/#{@icon}", nil)
      FileManager.copyPath_toPath_handler(@tmp_icon_path, icon_path, nil)
      prefs[:icon] = @tmp_icon_path.lastPathComponent()
      NSWorkspace.sharedWorkspace.objc_send :setIcon, @pref_icon.image,
                                            :forFile, BNDL_PATH,
                                            :options, 0
    end
    
    open(File.join(RSRC_PATH, "prefs.plist"), "w") do |f| 
      f.puts(prefs.to_plist)
    end
    
    # New Name
    if @name != prefs[:name]
      info = NSDictionary.dictionaryWithContentsOfFile(
          File.join(BNDL_PATH, "Contents", "Info.plist"))
      info.setValue_forKey(@pref_name.stringValue,"CFBundleName")
      info.writeToFile_atomically(
          File.join(BNDL_PATH, "Contents", "Info.plist"), false)
      FileManager.movePath_toPath_handler(
                BNDL_PATH,
                File.join(File.dirname(BNDL_PATH), "/#{prefs[:name]}.app"),
                nil)
      
      BNDL_PATH = File.join(File.dirname(NSBundle.mainBundle.bundlePath),
                            "#{prefs[:name]}.app")
      RSRC_PATH = File.join(BNDL_PATH, "Contents", "Resources")
    end
    
    alert = NSAlert.objc_send(
          :alertWithMessageText, "Preferences Changed",
          :defaultButton, "OK",
          :alternateButton, nil,
          :otherButton, nil,
          :informativeTextWithFormat, 
          "You will need to restart your application to see the changes")
    alert.setIcon(NSImage.imageNamed("NSInfo"))
    alert.objc_send(:beginSheetModalForWindow, @window,
                    :modalDelegate, nil,
                    :didEndSelector, nil,
                    :contextInfo, nil)
    @pref_window.orderOut self
  end

  ib_action :open_preferences do |sender|
    getPreferences()
    @pref_name.setStringValue(@name)
    @pref_port.setStringValue(@port)
    @pref_icon.setImage(
      NSImage.alloc.initWithContentsOfFile(File.join(RSRC_PATH,@icon)))
    @pref_window.makeKeyAndOrderFront(self)
  end

  # (end)
  
end

class NSTextView
  def appendString(str)
    len = self.textStorage.length
    replaceCharactersInRange_withString(NSMakeRange(len,0), str)
    scrollRangeToVisible(NSMakeRange(string.length, 0))    
  end
end