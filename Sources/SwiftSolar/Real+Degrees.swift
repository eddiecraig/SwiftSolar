//
//  File.swift
//  
//
//  Created by Eddie Craig on 18/02/2024.
//

import RealModule

extension Real {
    
    /// Reduces angle to within the first revolution
    /// by subtracting or adding even multiples of 360.0 until the
    /// result is `0.0..<360.0`
    var firstRevolution: Self {
        self - .init(360) * (self * .init(1) / .init(360)).rounded(.down)
    }
    
    ///Reduces angle to `+180...+180`
    var revolution180: Self {
        self - .init(360) * (self * .init(1) / .init(360) + .init(sign: .plus, exponent: -1, significand: .init(1))).rounded(.down)
    }
    
    var radians: Self { self * .pi / .init(180) }
    
    var degrees: Self { self * .init(180) / .pi }
    
    static func sind(_ x: Self) -> Self { .sin(x.radians) }
    static func tand(_ x: Self) -> Self { .tan(x.radians) }
    static func cosd(_ x: Self) -> Self { .cos(x.radians) }
    
    static func asind(_ x: Self) -> Self { .asin(x).degrees }
    static func atand(_ x: Self) -> Self { .atan(x).degrees }
    static func acosd(_ x: Self) -> Self { .acos(x).degrees }
    
    static func atan2d(y: Self, x: Self) -> Self { .atan2(y: y, x: x).degrees }
}
