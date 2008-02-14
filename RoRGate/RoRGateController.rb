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

  ib_outlet :name, :appPath, :iconPath, :port, :isIncluded, :iconDrawer, :drawerLabel, :drawerIcon
  attr_accessor :gatePath, :redrawer, :gateTemplatePath, :rorAppIcon


  def createGateFiles

    if !approveData
      alert = NSAlert.alertWithMessageText_defaultButton_alternateButton_otherButton_informativeTextWithFormat(
      "Required information missing",
      "ok",
      nil,
      nil,
      "You must provide a name and the path of the RoR app")
      alert.runModal
      #alert.beginSheetModalForWindow_modalDelegate_didEndSelector_contextInfo()
      return
    end
    #Path to the Gate.app copy
    @gatePath = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent(@name.stringValue + ".app")
    #Remove old copy
    system("rm -rf " + NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent("*.app"))
    #Create the app folder and uncompress contents
    FileManager.createDirectoryAtPath_attributes(@gatePath, nil)
    system("tar xzf " + GateTemplatePath + " -C " + @gatePath)	
    #Set icon
    iconPath = @iconPath.stringValue
    @rorAppIcon = @gatePath.stringByAppendingPathComponent("Contents/Resources/Icon.icns")
    FileManager.copyPath_toPath_handler(iconPath, @rorAppIcon, nil)
    #Set Preferences
    prefs = NSDictionary.dictionaryWithObjectsAndKeys(
    @name.stringValue, "name", 
    @appPath.stringValue, "path",
    #@isIncluded.intValue, "allIncPkg",
    @port.stringValue, "port", nil)
    prefs.writeToFile_atomically(@gatePath.stringByAppendingPathComponent("Contents/Resources/prefs.plist"), false)
    #Set Info.plist
    NSLog(@gatePath)
    info = NSDictionary.dictionaryWithContentsOfFile(@gatePath.stringByAppendingPathComponent("Contents/Info.plist")).mutableCopy()
    info.setValue_forKey(@name.stringValue,"CFBundleName")
    info.writeToFile_atomically(@gatePath.stringByAppendingPathComponent("Contents/Info.plist"), false)
    if @iconDrawer.state == 0
      @drawerLabel.setStringValue(@name.stringValue)
      @iconDrawer.open
    else
      @redrawer = 1
      @iconDrawer.close
    end
  end

  def approveData
    if @name.stringValue.empty? || @appPath.stringValue.empty?
      return false
    end
    true
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
