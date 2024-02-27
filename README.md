# Swift Solar

Swift Solar is a lightweight swift package for calculating astronomical times such as sun rise/set.

## Installation

To use Swift Solar in a SwiftPM project:

1. Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/eddiecraig/SwiftSolar", from: "1.0.0"),
```

2. Add `SwiftSolar` as a dependency for your target:

```swift
.target(name: "MyTarget", dependencies: [
  .product(name: "SwiftSolar", package: "SwiftSolar"),
  "AnotherModule"
]),
```

3. Add `import SwiftSolar` in your source code.

## Usage

The `Calculator` struct handles all calculations via the static func `riseSet(date: Date, coordinate: CLLocationCoordinate2D, event: AstronomicalEvent)` where `AstronomicalEvent` is a struct representing which rise/set event to calculate for. The func throws if the sun never rises or sets on the date for the specified event.

```swift
import SwiftSolar

    let sunriseSet = try Calculator.riseSet(date: Date(), coordinate: CLLocationCoordinate2D(), event: .sunriseSet)
    
    let ect = try Calculator.riseSet(date: Date(), coordinate: CLLocationCoordinate2D(), event: .civilTwilight)
```

## Platform Support

Supports all Apple platforms from iOS 16 onwards (and equivalents) using Swift 5.9.

## Dependencies

Extends [SwiftNumerics](https://github.com/apple/swift-numerics) for accurate trigonometric maths in degrees.

## Tests

Tests are included to compare `SwiftSolar`'s performance to the original code from `NTSolar`

## Acknowledgments

Inspired by code from Neil Tiffin, May 2019 & Performance Champions, Inc., May 2019. Which, in turn, came from C code originally from: [http://stjarnhimlen.se/comp/sunriset.c](http://stjarnhimlen.se/comp/sunriset.c)

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[Apache License Version 2.0](/LICENSE.txt)
