//
//  SourceEditorCommand.swift
//  CleanHelper
//
//  Created by Murat ŞENOL on 16.04.2023.
//

import Foundation
import XcodeKit
import AppKit

final class IsCalledGenerator: NSObject, XCSourceEditorCommand {
	
	let supportUTIs =
	[
		"com.apple.dt.playground",
		"public.swift-source",
		"com.apple.dt.playgroundpage"
	]
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
		var error: NSError?
        defer { completionHandler(error) }
		
		guard supportUTIs.contains(invocation.buffer.contentUTI) else {
			error = .init(domain: "Non-supported UTI!", code: 0)
			return
		}

        // At least something is selected
        guard let firstSelection = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            let lastSelection = invocation.buffer.selections.lastObject as? XCSourceTextRange else {
			error = .init(domain: "No selection!", code: 0)
                return
        }

        // One line is selected
        guard firstSelection.start.line < lastSelection.end.line else {
			error = .init(domain: "No selection!", code: 0)
            return
        }
        
        let lines = invocation.buffer.lines.compactMap { $0 as? String }
        let selectedLines = Array(lines[firstSelection.start.line...lastSelection.end.line])
        let lineOffset = firstSelection.start.line
        var instertedLineCount: Int = 0
        
        for i in 0..<selectedLines.count {
            let line = selectedLines[i]
            if line.contains("func") {
                guard let funcName = line.slice(from: "func", to: "(")?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    continue
                }
                
                invocation.buffer.lines.insert("\tvar \(funcName)IsCalled: Bool = false", at: i + lineOffset + instertedLineCount)
                instertedLineCount += 1
                invocation.buffer.lines.insert("\t\t\(funcName)IsCalled = true", at: i + 2 + lineOffset + instertedLineCount)
                instertedLineCount += 1
				
				// TODO: deff can be improved , right now just deleting a single line as expecting only < #code# > in function decleration
				invocation.buffer.lines.removeObject(at: i + lineOffset + instertedLineCount)
				instertedLineCount -= 1
            }
        }
        
    }
}

final class FillLogicProtocol: NSObject, XCSourceEditorCommand {
	
	let supportUTIs =
	[
		"com.apple.dt.playground",
		"public.swift-source",
		"com.apple.dt.playgroundpage"
	]
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
		var error: NSError?
        defer { completionHandler(error) }
	
		guard supportUTIs.contains(invocation.buffer.contentUTI) else {
			error = .init(domain: "Non-supported UTI!", code: 0)
			return
		}
        
        // At least something is selected
        guard let firstSelection = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            let lastSelection = invocation.buffer.selections.lastObject as? XCSourceTextRange else {
			error = .init(domain: "No selection!", code: 0)
			return
        }

        // One line is selected
        guard firstSelection.start.line < lastSelection.end.line else {
			error = .init(domain: "No selection!", code: 0)
            return
        }
         
        let lines = invocation.buffer.lines.compactMap { $0 as? String }
        let selectedLines = Array(lines[firstSelection.start.line...lastSelection.end.line])
		guard let protocolStartIndex = lines.firstIndex(where: {$0.contains("Logic: AnyObject")} ),
			  let prootocolLastIndex = lines.firstIndex(where: {$0.contains("}")}) else {
			error = .init(domain: "Couldn't find the corresponding Logic protocol for this file!", code: 0)
			return
		}
        
        clearLines(between: (protocolStartIndex+1)..<prootocolLastIndex, in: invocation)
        
        var functionDeclaretions: [String] = []
        
        for i in 0..<selectedLines.count {
            let line = selectedLines[i]
            
			if !line.contains("private") && line.contains("func") {
                functionDeclaretions.append(line.before(throughLast: ")"))
            }
        }
        
        for i in 0..<functionDeclaretions.count {
            invocation.buffer.lines.insert(functionDeclaretions[i], at: protocolStartIndex + 1 + i)
        }
    }
    
    func clearLines(between range: CountableRange<Int>, in invocation: XCSourceEditorCommandInvocation) {
        guard range.upperBound < invocation.buffer.lines.count, range.lowerBound >= 0 else {
            return
        }
        
        for _ in range {
            invocation.buffer.lines.removeObject(at: range.startIndex)
        }
    }
}

final class CopyFunctionDeclerations: NSObject, XCSourceEditorCommand {
    
	let supportUTIs =
	[
		"com.apple.dt.playground",
		"public.swift-source",
		"com.apple.dt.playgroundpage"
	]
	
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
		var error: NSError?
        defer { completionHandler(error) }
		
		guard supportUTIs.contains(invocation.buffer.contentUTI) else {
			error = .init(domain: "Non-supported UTI!", code: 0)
			return
		}

        // At least something is selected
        guard let firstSelection = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            let lastSelection = invocation.buffer.selections.lastObject as? XCSourceTextRange else {
			error = .init(domain: "No selection!", code: 0)
                return
        }

        // One line is selected
        guard firstSelection.start.line < lastSelection.end.line else {
			error = .init(domain: "No selection!", code: 0)
            return
        }
        
        let lines = invocation.buffer.lines.compactMap { $0 as? String }
        let selectedLines = Array(lines[firstSelection.start.line...lastSelection.end.line])
        
        var functionDeclaretions: [String] = []
        
        for i in 0..<selectedLines.count {
            let line = selectedLines[i]
            
			if !line.contains("private") && line.contains("func") {
                functionDeclaretions.append(line.before(throughLast: ")"))
            }
            
        }
        
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        clipboard.declareTypes([.string], owner: nil)
        clipboard.setString(functionDeclaretions.joined(separator: "\n"), forType: .string)
    }
}

extension String {
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func before(first delimiter: Character) -> String {
        if let index = firstIndex(of: delimiter) {
            let before = prefix(upTo: index)
            return String(before)
        }
        return ""
    }
    
    func before(throughFirst delimiter: Character) -> String {
        if let index = firstIndex(of: delimiter) {
            let before = prefix(through: index)
            return String(before)
        }
        return ""
    }
    
    func after(first delimiter: Character) -> String {
        if let index = firstIndex(of: delimiter) {
            let after = suffix(from: index).dropFirst()
            return String(after)
        }
        return ""
    }
    
    func before(last delimiter: Character) -> String {
        if let index = lastIndex(of: delimiter) {
            let before = prefix(upTo: index)
            return String(before)
        }
        return ""
    }
    
    func before(throughLast delimiter: Character) -> String {
        if let index = lastIndex(of: delimiter) {
            let before = prefix(through: index)
            return String(before)
        }
        return ""
    }
    
    func after(last delimiter: Character) -> String {
        if let index = lastIndex(of: delimiter) {
            let after = suffix(from: index).dropFirst()
            return String(after)
        }
        return ""
    }
}
