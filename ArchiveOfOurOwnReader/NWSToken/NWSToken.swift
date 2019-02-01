//
//  NWSToken.swift
//  NWSTokenView
//
//  Created by James Hickman on 8/11/15.
/*
Copyright (c) 2015 Appmazo, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.//
*/

import UIKit

open class NWSToken: UIView
{
    open var hiddenTextView = UITextView()
    open var isSelected: Bool = false

    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        // Hide text view (for using keyboard to delete token)
        hiddenTextView.isHidden = true
        hiddenTextView.text = "NWSTokenDeleteKey" // Set default text for detection in delegate
        hiddenTextView.autocorrectionType = UITextAutocorrectionType.no // Hide suggestions to prevent key from being displayed
        addSubview(hiddenTextView)
    }
}
