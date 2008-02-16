#
#  RoRGateController.rb
#  RoRGate
#
#  Created by Juan Germán Castañeda Echevarría on 2/7/08.
#  Copyright (c) 2008 Castech. All rights reserved.
#

require 'osx/cocoa'
include OSX

GateTemplatePath = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("Contents.tgz")
FileManager = NSFileManager.defaultManager

class RoRGateController < NSObject

  ib_outlet :window
  ib_outlet :name, :appPath, :iconPath, :port, :isIncluded
  ib_outlet :iconDrawer, :drawerLabel, :drawerIcon
  
  attr_accessor :gatePath, :redrawer, :gateTemplatePath, :rorAppIcon


  def createGateFiles
    return unless approve_data()

    @gatePath = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent(@name.stringValue + ".app")
    system("rm -rf " + NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("*.app"))
    
    create_gate_dir()
    if @isIncluded.intValue == 1
      FileManager.copyPath_toPath_handler(
        @appPath.stringValue,
        @gatePath.stringByAppendingPathComponent("Contents/Resources/rorApp"),
        nil)
    end
    create_preferences()

    set_info()
    toggle_drawer()
  end

  def approve_data
    if @name.stringValue.empty? || @appPath.stringValue.empty?
      alert = NSAlert.alertWithMessageText_defaultButton_alternateButton_otherButton_informativeTextWithFormat(
            "Required information missing",
            "OK",
            nil,
            nil,
            "You must provide a name and the path of the RoR app")
      alert.setIcon(NSImage.imageNamed("NSInfo"))
      alert.beginSheetModalForWindow_modalDelegate_didEndSelector_contextInfo(@window, nil, nil, nil)      
      return false
    end
    true
  end
  
  def create_gate_dir
    FileManager.createDirectoryAtPath_attributes(@gatePath, nil)
    system("tar xzf " + GateTemplatePath + " -C " + @gatePath)	
    iconPath = @iconPath.stringValue
    @rorAppIcon = @gatePath.stringByAppendingPathComponent("Contents/Resources/Icon.icns")
    FileManager.copyPath_toPath_handler(iconPath, @rorAppIcon, nil)
  end

  def create_preferences()
    port = (@port.stringValue.empty?)? "3000" : @port.stringValue 
    prefs = NSDictionary.dictionaryWithObjectsAndKeys(
		  @name.stringValue, "name", 
		  @appPath.stringValue, "path",
		  port, "port",
		  @isIncluded.intValue, "allIncPkg", nil)
    prefs.writeToFile_atomically(@gatePath.stringByAppendingPathComponent("Contents/Resources/prefs.plist"), false)
  end

  def set_info
    info = NSDictionary.dictionaryWithContentsOfFile(@gatePath.stringByAppendingPathComponent("Contents/Info.plist")).mutableCopy()
    info.setValue_forKey(@name.stringValue,"CFBundleName")
    info.writeToFile_atomically(@gatePath.stringByAppendingPathComponent("Contents/Info.plist"), false)
  end

  def toggle_drawer
    if @iconDrawer.state == 0
      @drawerLabel.setStringValue(@name.stringValue)
      @iconDrawer.open
    else
      @redrawer = 1
      @iconDrawer.close
    end
  end

  def selectRoRAppPath
    oPanel = NSOpenPanel.openPanel
    oPanel.setCanChooseFiles false
    oPanel.setCanChooseDirectories true

    result = oPanel.runModalForDirectory_file_types(NSHomeDirectory(), nil, nil)

    if result == NSOKButton
      path = oPanel.filenames.objectAtIndex 0
      @appPath.setStringValue path
    end
  end

  def selectIcon
    oPanel = NSOpenPanel.openPanel
    oPanel.setCanChooseFiles true
    oPanel.setCanChooseDirectories false

    fileTypes = NSArray.arrayWithObject("icns")
    result = oPanel.runModalForDirectory_file_types(NSHomeDirectory(), nil, fileTypes)

    if result == NSOKButton
      path = oPanel.filenames.objectAtIndex 0
      @iconPath.setStringValue path
    end
  end

  def drawerDidClose(notification)
    if @redrawer == 1
      @drawerLabel.setStringValue(@name.stringValue)
      @iconDrawer.open
      @redrawer = 0
    end
  end

end
