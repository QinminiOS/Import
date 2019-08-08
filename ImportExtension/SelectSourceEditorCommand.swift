//
//  SelectSourceEditorCommand.swift
//  ImportExtension
//
//  Created by Qinmin on 04/10/2018.
//  Copyright © 2018 Qinmin. All rights reserved.
//

import Foundation
import XcodeKit

class SelectSourceEditorCommand: NSObject, XCSourceEditorCommand
{
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void
    {
        //check selections count
        guard invocation.buffer.selections.count == 1 else
        {
            completionHandler(nil);
            return
        }
        
        //must be one line
        let selection: XCSourceTextRange = invocation.buffer.selections.firstObject as! XCSourceTextRange;
        
        guard selection.start.line == selection.end.line else
        {
            completionHandler(nil);
            return
        }
        
        //handle
        var selectedString = "";
        var lastImportLineIndex = -1;
        
        //find the last import line index & selected string
        let lines = invocation.buffer.lines as! [String];
        for (idx, line) in lines.enumerated()
        {
            // let line = invocation.buffer.lines[idx];
            
            let importLine = self.isOcSource(invocation: invocation) ? "#import" : "import ";
            
            if line.hasPrefix(importLine)
            {
                lastImportLineIndex = idx;
            }
            
            if idx == selection.start.line
            {
                let start = line.index(line.startIndex, offsetBy: selection.start.column)
                let end = line.index(line.startIndex, offsetBy: selection.end.column)
                selectedString = String(line[start..<end])
                
                break;
            }
        }
        
        //check selected string
        let trimString = selectedString.trimmingCharacters(in: CharacterSet.whitespaces)
        
        guard (trimString.count > 0 || !trimString.elementsEqual("\n")) else
        {
            completionHandler(nil);
            return;
        }
        
        //check invocation contains import string
        let importString = self.isOcSource(invocation: invocation) ? "#import \"\(selectedString).h\"" : "import \(selectedString)";
        
        guard !invocation.buffer.completeBuffer.contains(importString) else
        {
            completionHandler(nil);
            return;
        }
        
        let lineForEmpty = self.lineForEmptyImportLine(lines: lines, invocation: invocation);
        
        let lineForAboveClassDefinition = self.lineForAboveClassDefinition(lines: lines, invocation: invocation);
        
        //file contains #import lines
        if (lastImportLineIndex != -1)
        {
            invocation.buffer.lines.insert(importString, at: lastImportLineIndex+1)
            
        }
        //file does not contains #import lines,put it in first line under comment
        else if(lineForEmpty != -1)
        {
            invocation.buffer.lines.insert(importString, at:lineForEmpty+1);
            
        }
        else if(lineForAboveClassDefinition != -1)
        {
            invocation.buffer.lines.insert(importString, at:lineForAboveClassDefinition+1);
        }
        
        completionHandler(nil)
    }
    
    func isOcSource(invocation : XCSourceEditorCommandInvocation) -> Bool
    {   
        return !(invocation.buffer.contentUTI == "public.swift-source")
    }
    
    func lineForEmptyImportLine(lines:[String],
                                invocation:XCSourceEditorCommandInvocation) -> Int
    {
        for (i, lineString) in lines.enumerated()
        {
            
            if lineString.hasPrefix("//")
            {
                continue;
            }
            
            if lineString.elementsEqual("\n")
            {
                return i;
            }
            
            let prefix = self.isOcSource(invocation: invocation) ? "@" : "class";

            if lineString.hasPrefix(prefix)
            {
                return -1;
            }
        }
        
        return -1;
    }
    
    func lineForAboveClassDefinition(lines:[String],
                                invocation:XCSourceEditorCommandInvocation) -> Int
    {
        
        for (i, lineString) in lines.enumerated()
        {
            
            if lineString.hasPrefix("//")
            {
                continue;
            }
            
            let prefix = self.isOcSource(invocation: invocation) ? "@" : "class";
            
            if lineString.hasPrefix(prefix)
            {
                return i > 1 ? (i - 1) : 0;
            }
        }
        
        return -1;
    }
    
}
