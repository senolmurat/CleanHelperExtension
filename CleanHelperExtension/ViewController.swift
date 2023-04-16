//
//  ViewController.swift
//  CleanHelperExtension
//
//  Created by Murat ŞENOL on 16.04.2023.
//

import Cocoa

class ViewController: NSViewController {

	@IBOutlet private var textView: NSTextView!
	
	override func viewDidLoad() {
        super.viewDidLoad()

		textView.isSelectable = false
		textView.isEditable = false
    }
	
	override func viewDidAppear() {
		super.viewDidAppear()
		self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
		self.view.window?.title = "Clean Helper"
	}
}

