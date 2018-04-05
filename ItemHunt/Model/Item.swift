//
//  Item.swift
//  ItemHunt
//
//  Created by Igor Eydman on 3/31/18.
//  Copyright © 2018 Igor Eydman. All rights reserved.
//

import Foundation

class Item {
    private var _name: String
    private var _emoji: String
    
    var name: String {
        return _name
    }
    
    var emoji: String {
        return _emoji
    }
    
    init(name: String, emoji: String) {
        self._name = name
        self._emoji = emoji
    }
    
}
