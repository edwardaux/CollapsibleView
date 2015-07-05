//
//  CollapsibleView.swift
//  CollapsibleView
//
//  Created by Craig Edwards on 25/06/2015.
//  Copyright (c) 2015 Craig Edwards. All rights reserved.
//

import Foundation
import Cocoa

/**
CollapsibleView is an NSView subclass that offers the user the ability to collapse 
and expand the contents using a disclosure indicator. Conceptually, it looks like:

	+---------------------------+
	| > A title goes here       |
	+---------------------------+

and when the user clicks on the disclosure indicator, it toggles to:

	+---------------------------+
	| v A title goes here       |
	+---------------------------+
	|                           |
	|   your views goes here    |
	|                           |
	+---------------------------+

CollapsibleView plays nicely with Interface Builder in that it provides several
IBDesignable fields that allow you to easily customize the title, initial
expansion state, and some margin details. It also offers an IBOutlet for the 
contents of the main view.

Usage it is as simple as dragging a new Custom View into your view somewhere and
changing its Custom Class type to CollapsibleView.  In the Attributes Inspector
you can then override the default settings - the most likely are the contents of
the title and the initial expansion state (ie. expanded or collapsed)
*/
@IBDesignable public class CollapsibleView : NSView {
	/**
	The disclosure title
	*/
	@IBInspectable public var contentTitle: String = "Title goes here"
	
	/**
	The expanded/collapsed state of the view
	*/
	@IBInspectable public var expanded: Bool = true
	
	/**
	The width of the disclosure button
	*/
	@IBInspectable public var buttonWidth: Int = 15
	
	/**
	The height of the disclosure button
	*/
	@IBInspectable public var buttonHeight: Int = 13
	
	/**
	The margin to the left of the disclosure button
	*/
	@IBInspectable public var buttonMargin: Int = 0
	
	/**
	The margin between the the title label and the top of the title view
	*/
	@IBInspectable public var titleTopMargin: Int = 0
	
	/**
	The margin between the the title label and the bottom of the title view
	*/
	@IBInspectable public var titleBottomMargin: Int = 0
	
	/**
	The margin between the disclosure button and the title label
	*/
	@IBInspectable public var titleLeftMargin: Int = 0
	
	/**
	The margin to the right of the title label
	*/
	@IBInspectable public var titleRightMargin: Int = 0

	/**
	The contents of the main expansion view. Must be set via an outlet or code prior to 
	adding this view to superview.
	*/
	@IBOutlet public weak var contentView: NSView! {
		didSet {
			self.replaceContentView(oldValue, with:contentView)
		}
	}

	/**
	The delegate that will get called when interesting things happen. Note that it is
	declared as an AnyObject due to an Xcode 6.x bug where you can't connect to an IBOutlet
	that is declared as a protocol. Once that is fixed, the type of this variable will
	be changed back to an optional CollapsibleViewDelegate
	*/
	@IBOutlet public weak var delegate: AnyObject?
	
	/**
	Container for the disclosure button and label
	*/
	public var titleView = NSView(frame: NSZeroRect)
	
	/**
	The disclosure button
	*/
	public var titleDisclosureButton = NSButton(frame: NSZeroRect)
	
	/**
	The title label
	*/
	public var titleText = NSTextField(frame: NSZeroRect)
	
	/**
	The container for the content view. This is the view that expands/collapses
	*/
	public var expansionView = NSView(frame: NSZeroRect)
	
	/**
	The height of the expansionView. Used to restore expansion back to the expanded state.
	*/
	private var expansionHeight = CGFloat(0)
	
	/**
	The constraint that animates the expand/collapse animation. Note that it isn't set up until
	the updateConstraints() function is run.
	*/
	private var expansionConstraint: NSLayoutConstraint!
	
	override public func updateConstraints() {
		self.titleView.translatesAutoresizingMaskIntoConstraints = false
		self.titleView.identifier = "titleView"

		self.titleDisclosureButton.translatesAutoresizingMaskIntoConstraints = false
		self.titleDisclosureButton.identifier = "disclosureButton"
		self.titleDisclosureButton.setButtonType(.MomentaryChangeButton)
		self.titleDisclosureButton.bordered = false
		self.titleDisclosureButton.focusRingType = .None
		self.titleDisclosureButton.title = self.titleDisclosureButtonText()
		self.titleDisclosureButton.target = self
		self.titleDisclosureButton.action = "toggleExpand:"

		self.titleText.translatesAutoresizingMaskIntoConstraints = false
		self.titleText.identifier = "titleText"
		self.titleText.editable = false
		self.titleText.bezeled = false
		self.titleText.drawsBackground = false
		self.titleText.stringValue = self.contentTitle
		
		self.titleView.addSubview(self.titleDisclosureButton)
		self.titleView.addSubview(self.titleText)
		
		self.expansionView.translatesAutoresizingMaskIntoConstraints = false
		self.expansionView.identifier = "expansionView"

		self.addSubview(self.titleView)
		self.addSubview(self.expansionView)
		
		let metrics = [
			"buttonWidth"       : self.buttonWidth,
			"buttonHeight"      : self.buttonHeight,
			"buttonMargin"      : self.buttonMargin,
			"titleTopMargin"    : self.titleTopMargin,
			"titleBottomMargin" : self.titleBottomMargin,
			"titleLeftMargin"   : self.titleLeftMargin,
			"titleRightMargin"  : self.titleRightMargin,
		]
		let views = [
			"titleView"     : self.titleView,
			"expansionView" : self.expansionView,
			"button"        : self.titleDisclosureButton,
			"title"         : self.titleText
		]
		// both title and expansion views should fill this view horizontally. the title view height should be set to
		// the titleHeight and be abutted next to the expansionView. We also add a weak constraint to support the 
		// expanding/collapsing
		self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleView]|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
		self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[expansionView]|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
		self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(titleTopMargin)-[titleView]-(titleBottomMargin)-[expansionView]-(0@600)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))

		// the button needs to be constrained to its width and height
		self.titleDisclosureButton.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[button(==buttonWidth)]", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
		self.titleDisclosureButton.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[button(==buttonHeight)]", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))

		// horizontally, the title is laid out as: padding + button + padding + title + padding.  vertically, it
		// is laid out with both the button and title label pinned to the top of the titleView
		self.titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-buttonMargin-[button]-titleLeftMargin-[title]-titleRightMargin-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
		self.titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[button]", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
		self.titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[title]|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))

		// depending on the initial expansion state, the expansion constraint constant will be set to the 
		// height of the contentView or 0.
		let initialHeight = self.expanded ? self.expansionHeight : 0
		self.expansionConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: self.titleView, attribute: .Bottom, multiplier: 1, constant: initialHeight)
		self.addConstraint(self.expansionConstraint)

		// and hand off to the superclass
		super.updateConstraints()
	}
	
	/**
	Sets the passed view as the contentView. Called whenever the contentView is replaced (normally this would be through an IBOutlet)
	*/
	public func replaceContentView(oldContentView: NSView?, with newView: NSView) {
		// if we already have an contentView, then we remove it now
		if let oldContentView = oldContentView {
			oldContentView.removeFromSuperview()
		}

		// add this view to the expansionView and hang on to whatever its height is
		newView.translatesAutoresizingMaskIntoConstraints = false
		self.expansionView.addSubview(newView)
		self.expansionHeight = self.contentView.frame.height
		
		// make sure that this view fills the expansionView
		var views : [String: NSView] = ["view": newView]
		self.expansionView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
		self.expansionView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
	}
	
	/**
	Sets the collapsed/expanded state. Can be explicitly called by external sources, but is usually invoked
	by the disclosure button.
	*/
	public func collapseOrExpand(expand: Bool) {
		if expand {
			NSAnimationContext.runAnimationGroup({ context in
				context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
				self.expansionConstraint!.animator().constant = self.expansionHeight
			}, completionHandler: nil)
		}
		else {
			NSAnimationContext.runAnimationGroup({ context in
				context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
				self.expansionConstraint!.animator().constant = 0
			}, completionHandler: nil)
		}
		self.expanded = expand
		self.titleDisclosureButton.title = self.titleDisclosureButtonText()
		
		// call the delegate - if it is set, and if it implements the correct func
		self.delegate?.collapsibleView?(self, didExpand: self.expanded)
	}

	/**
	Disclosure button target-action callback
	*/
	public func toggleExpand(sender: AnyObject?) {
		self.collapseOrExpand(!self.expanded)
	}
	
	/**
	Returns the disclosure button text based on the current expansion state
	*/
	public func titleDisclosureButtonText() -> String {
		return self.expanded ? "▼" : "►"
	}
}

/**
Classes can implement this if they are interested in CollapsibleView events
*/
@objc protocol CollapsibleViewDelegate {
	optional func collapsibleView(collapsibleView: CollapsibleView, didExpand expanded: Bool)
}
