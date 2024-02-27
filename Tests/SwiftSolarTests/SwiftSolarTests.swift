import XCTest
import CoreLocation
@testable import SwiftSolar

/// Tests to compare `SwiftSolar` to the original code from `NTSolar`
final class SwiftSolarTests: XCTestCase {
    
    func testAngleDegreeToRadian() throws {
        XCTAssertEqual(180.0.radians, .pi, "180 degrees does not equal PI radians")
    }
    
    func testAngleRadianToDegrees() throws {
        XCTAssertEqual(.pi.degrees, 180, "PI radians does not equal 180 degrees")
    }
    
    func testCosine() throws {
        XCTAssertEqual(.cosd(90), 0.0, accuracy: 0.0000001, "COS")
        XCTAssertEqual(.cosd(0), 1.0, accuracy: 0.0000001, "COS")
    }
    
    func testSine() throws {
        XCTAssertEqual(.sind(180), 0.0, accuracy: 0.0000001, "SIN")
        XCTAssertEqual(.sind(90), 1.0, accuracy: 0.0000001, "SIN")
    }
    
    func testTangent() throws {
        XCTAssertEqual(.tand(180), 0.0, accuracy: 0.0000001, "TAN")
        XCTAssertEqual(.tand(0), 0.0, accuracy: 0.0000001, "TAN")
    }
    
    func testRevolution() throws {
        for x in stride(from: 0, through: 720, by: 0.1) {
            XCTAssertEqual(x.firstRevolution, NTSolar.revolution(x: x), accuracy: 0.0000001, "Revolution")
            XCTAssertEqual(x.revolution180, NTSolar.rev180(x: x), accuracy: 0.0000001, "Revolution180")
        }
    }
    
    func testGMST0() throws {
        for d in stride(from: -8000, through: 8000, by: 0.1) {
            XCTAssertEqual(Calculator.gmst0(d: d), NTSolar.GMST0(d: d), accuracy: 0.0000001, "GMST0")
        }
    }
    
    func testSunpos() throws {
        for d in stride(from: -8000, through: 8000, by: 0.1) {
            let newSunpos = Calculator.sunpos(d: d)
            let oldSunpos = NTSolar.sunpos(d: d)
            XCTAssertEqual(newSunpos.lon, oldSunpos.lon, accuracy: 0.0000001, "Sunpos.lon")
            XCTAssertEqual(newSunpos.r, oldSunpos.r, accuracy: 0.0000001, "Sunpos.r")
        }
    }
    
    func testSun_RA_dec() throws {
        for d in stride(from: -8000, through: 8000, by: 0.1) {
            let newSun_RA_dec = Calculator.sun_RA_dec(d: d)
            let oldSun_RA_dec = NTSolar.sun_RA_dec(d: d)
            XCTAssertEqual(newSun_RA_dec.RA, oldSun_RA_dec.RA, accuracy: 0.0000001, "Sun_RA_dec.RA")
            XCTAssertEqual(newSun_RA_dec.dec, oldSun_RA_dec.dec, accuracy: 0.0000001, "Sun_RA_dec.dec")
            XCTAssertEqual(newSun_RA_dec.r, oldSun_RA_dec.r, accuracy: 0.0000001, "Sun_RA_dec.r")
        }
    }
    
    func testDayLen() throws {
        XCTAssertEqual(
            Calculator.daylen(year: 2024, month: 2, day: 16, coordinate: .western),
            NTSolar.day_length(year: 2024, month: 2, day: 16, lon: CLLocationCoordinate2D.western.longitude, lat: CLLocationCoordinate2D.western.latitude),
            accuracy: 0.0000001,
            "dayLen"
        )
    }
    
    func testCivilTwilight() throws {
        XCTAssertEqual(
            Calculator.daylen(year: 2024, month: 2, day: 16, coordinate: .western, event: .civilTwilight),
            NTSolar.day_civil_twilight_length(year: 2024, month: 2, day: 16, lon: CLLocationCoordinate2D.western.longitude, lat: CLLocationCoordinate2D.western.latitude),
            accuracy: 0.0000001,
            "dayLen"
        )
    }
    
    func testNauticalTwilight() throws {
        XCTAssertEqual(
            Calculator.daylen(year: 2024, month: 2, day: 16, coordinate: .western, event: .nauticalTwilight),
            NTSolar.day_nautical_twilight_length(year: 2024, month: 2, day: 16, lon: CLLocationCoordinate2D.western.longitude, lat: CLLocationCoordinate2D.western.latitude),
            accuracy: 0.0000001,
            "dayLen"
        )
    }
    
    func testAstronomicalTwilight() throws {
        XCTAssertEqual(
            Calculator.daylen(year: 2024, month: 2, day: 16, coordinate: .western, event: .astronomicalTwilight),
            NTSolar.day_astronomical_twilight_length(year: 2024, month: 2, day: 16, lon: CLLocationCoordinate2D.western.longitude, lat: CLLocationCoordinate2D.western.latitude),
            accuracy: 0.0000001,
            "dayLen"
        )
    }
    
    func testSunrise() throws {
        for location in [CLLocationCoordinate2D.western, .zero, .southern, .eastern] {
            for timeInterval in stride(from: Date().timeIntervalSince1970, through: Date().timeIntervalSince1970 + 60 * 60 * 24 * 365 * 20, by: 60 * 60 * 24) {
                let date = Date(timeIntervalSince1970: timeInterval)
                let comps = Calendar.current.dateComponents([.day, .month, .year], from: date)
                let day = comps.day ?? 0
                let month = comps.month ?? 0
                let year = comps.year ?? 0
                let rise = NTSolar.sun_rise_set(year: year, month: month, day: day, lon: location.longitude, lat: location.latitude).trise
                XCTAssertEqual(
                    try Calculator.riseSet(year: year, month: month, day: day, coordinate: location, event: .sunriseSet).lowerBound,
                    rise,
                    accuracy: 0.0000001,
                    "Sun rise"
                )
            }
        }
    }
}

extension CLLocationCoordinate2D {

    static let western = CLLocationCoordinate2D(latitude: 53.248, longitude: -4.535)
    static let zero = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    static let southern = CLLocationCoordinate2D(latitude: -41.23, longitude: -6.345)
    static let eastern = CLLocationCoordinate2D(latitude: 32.342, longitude: 54.340)
}
