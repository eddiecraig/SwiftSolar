
import Foundation
import RealModule
import CoreLocation

/// Struct to calculate sunrise & sunset times.
///
/// Inspired by code from Neil Tiffin, May 2019 & Performance Champions, Inc., May 2019
/// Which, in turn, came from C code originally from: [http://stjarnhimlen.se/comp/sunriset.c](http://stjarnhimlen.se/comp/sunriset.c)

public struct Calculator {
    
    /// Compute the number of days elapsed since 2000 Jan 0.0
    /// (which is equal to 1999 Dec 31, 0h UT)
    private static func daysSince2000Jan0(year:Int, month:Int, day:Int) -> Int {
        367*(year)-((7*((year)+(((month)+9)/12)))/4)+((275*(month))/9)+(day)-730530
    }
    
    /// Calculates rise and set times for specified event
    /// - Parameters:
    ///   - date: Date for calculation
    ///   - coordinate: Location for calculation
    ///   - event: Astronomical event to calculate rise and set times for
    /// - Returns: Date interval of rise and set
    public static func riseSet(date: Date, coordinate: CLLocationCoordinate2D, event: AstronomicalEvent) throws -> DateInterval {
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: date)
        guard let day = comps.day, let month = comps.month, let year = comps.year else {
            throw Error.invalidDate
        }
        let utcHours = try riseSet(year: year, month: month, day: day, coordinate: coordinate, event: event)
        var components = DateComponents(
            timeZone: .gmt,
            year: year,
            month: month,
            day: day,
            second: Int((utcHours.lowerBound * 60 * 60).rounded())
        )
        let rise = Calendar(identifier: .gregorian).date(from: components) ?? .distantPast
        components.second = Int((utcHours.upperBound * 60 * 60).rounded())
        let set = Calendar(identifier: .gregorian).date(from: components) ?? .distantPast
        
        return DateInterval(start: rise, end: set)
    }
    
    /// Calculate rise/set times for different astronomical events
    ///
    /// - Parameters:
    ///   - year: calendar date, 1801-2099 only.
    ///   - month: calendar date, 1801-2099 only.
    ///   - day: calendar date, 1801-2099 only.
    ///   - coordinate: Location for calculation. The longitude value IS critical in this function!
    ///   - event: Astronomical event to calculate rise and set times for
    /// - Returns: Range of rise and set in hours UTC.
    ///     Both times in hours UT are relative to the specified altitude,
    ///     and thus this function can be used to compute
    ///     various twilight times, as well as rise/set times.
    /// - Throws: `Calculator.Error` if the sun is always above or below the specified horizon.
    static func riseSet(year: Int, month: Int, day: Int, coordinate: CLLocationCoordinate2D, event: AstronomicalEvent) throws -> ClosedRange<Double> {
        
        var altit = event.sunAltitude
        var d: Double          // Days since 2000 Jan 0.0 (negative before)
        var sr: Double         // Solar distance, astronomical units
        var sRA: Double        // Sun's Right Ascension
        var sdec: Double       // Sun's declination
        var sradius: Double    // Sun's apparent radius
        var t: Double          // Diurnal arc
        var tsouth: Double     // Time when Sun is at south
        var sidtime: Double    // Local sidereal time
        
        // Compute d of 12h local mean solar time
        d = Double(daysSince2000Jan0(year: year, month: month, day: day)) + 0.5 - coordinate.longitude / 360.0
        
        // Compute the local sidereal time of this moment
        sidtime = (gmst0(d: d) + 180.0 + coordinate.longitude).firstRevolution
        
        // Compute Sun's RA, Decl and distance at this moment
        (sRA, sdec, sr) = sun_RA_dec(d: d)
        
        // Compute time when Sun is at south - in hours UT
        tsouth = 12.0 - (sidtime - sRA).revolution180 / 15.0
        
        // Compute the Sun's apparent radius in degrees
        sradius = 0.2666 / sr
        
        // Do correction to upper limb, if necessary
        if event.upperLimb {
            altit -= sradius
        }
        
        // Compute the diurnal arc that the Sun traverses to reach the specified altitude altit:
        let cost: Double = (.sind(altit) - .sind(coordinate.latitude) * .sind(sdec)) / (.cosd(coordinate.latitude) * .cosd(sdec))
        if ( cost >= 1.0 ) {
            throw Error.sunAlwaysBelow
        }
        else if ( cost <= -1.0 ) {
            throw Error.sunAlwaysAbove
        }
        else {
            t = .acosd(cost) / 15.0   /* The diurnal arc, hours */
        }
        
        // Store rise and set times - in hours UTC
        
        let trise = tsouth - t
        let tset  = tsouth + t
        return trise...tset
    }
    
    enum Error: LocalizedError {
        case sunAlwaysAbove, sunAlwaysBelow, invalidDate
    }
    
    /// The "workhorse" function
    /// - Parameters:
    ///   - year: Calendar year
    ///   - month: Calendar month
    ///   - day: Calendar day
    ///   - coordinate: Location
    ///   - event: Astronomical event to calculate rise and set times for
    /// - Returns: Diurnal arc in hours
    ///
    /// Calendar date must be between year 1801-2099 only.
    /// The longitude value is not critical. Set it to the correct
    /// longitude if you're picky, otherwise set to to, say, 0.0
    /// The latitude however IS critical - be sure to get it correct
    static func daylen(year: Int, month: Int, day: Int, coordinate: CLLocationCoordinate2D, event: AstronomicalEvent = .sunriseSet) -> Double {
        
        var altit = event.sunAltitude
        var d: Double          // Days since 2000 Jan 0.0 (negative before)
        var obl_ecl: Double    // Obliquity (inclination) of Earth's axis
        var sr: Double         // Solar distance, astronomical units
        var slon: Double       // True solar longitude
        var sin_sdecl: Double  // Sine of Sun's declination
        var cos_sdecl: Double  // Cosine of Sun's declination
        var sradius: Double    // Sun's apparent radius
        
        // Compute d of 12h local mean solar time
        d = Double(daysSince2000Jan0(year: year, month: month, day: day)) + 0.5 - coordinate.longitude / 360.0
        
        // Compute obliquity of ecliptic (inclination of Earth's axis)
        obl_ecl = 23.4393 - 3.563E-7 * d
        
        // Compute Sun's ecliptic longitude and distance
        (slon, sr) = sunpos(d: d)
        
        // Compute sine and cosine of Sun's declination
        sin_sdecl = .sind(obl_ecl) * .sind(slon)
        cos_sdecl = (1.0 - sin_sdecl * sin_sdecl).squareRoot()
        
        // Compute the Sun's apparent radius, degrees
        sradius = 0.2666 / sr
        
        // Do correction to upper limb, if necessary
        if event.upperLimb {
            altit -= sradius
        }
        
        // Compute the diurnal arc that the Sun traverses to reach the specified altitude altit
        let cost = (.sind(altit) - .sind(coordinate.latitude) * sin_sdecl) / (.cosd(coordinate.latitude) * cos_sdecl)
        return switch cost {
        case 1.0...:    // Sun always below altit
            0.0
        case ...(-1):   // Sun always above altit
            24.0
        default:        // The diurnal arc
            (2.0/15.0) * .acosd(cost)
        }
    }
    
    /// Computes the Sun's equatorial coordinates `RA`, `dec`
    /// and also its distance `r`, at an instant given in d,
    /// the number of days since 2000 Jan 0.0.
    static func sun_RA_dec(d: Double) -> (RA: Double, dec: Double, r: Double) {
        
        var obl_ecl: Double
        var x: Double
        var y: Double
        var z: Double
        
        // Compute Sun's ecliptical coordinates
        let (lon, r) = sunpos(d: d)
        
        // Compute ecliptic rectangular coordinates (z=0)
        x = r * .cosd(lon)
        y = r * .sind(lon)
        
        // Compute obliquity of ecliptic (inclination of Earth's axis)
        obl_ecl = 23.4393 - 3.563E-7 * d
        
        // Convert to equatorial rectangular coordinates - x is unchanged
        z = y * .sind(obl_ecl)
        y = y * .cosd(obl_ecl)
        
        // Convert to spherical coordinates
        let RA: Double = .atan2d(y: y, x: x)
        let dec: Double = .atan2d( y: z, x: (.pow(x, 2) + .pow(y, 2)).squareRoot() )
        return (RA, dec, r)
    }
    
    /// Computes the Sun's ecliptic longitude and distance
    /// at an instant. The Sun's ecliptic latitude is not
    /// computed, since it's always very near 0.
    /// - Parameter d: Number of days since 2000 Jan 0.0
    /// - Returns: lon: True solar longitude, r: Solar distance
    static func sunpos(d: Double) -> (lon: Double, r: Double) {
        
        var M: Double   // Mean anomaly of the Sun
        var w: Double   // Mean longitude of perihelion
        // Note: Sun's mean longitude = M + w
        var e: Double   // Eccentricity of Earth's orbit
        var E: Double   // Eccentric anomaly
        var x: Double   // x coordinate in orbit
        var y: Double   // y coordinate in orbit
        var v: Double   // True anomaly
        
        // Compute mean elements
        M = (356.0470 + 0.9856002585 * d).firstRevolution
        w = 282.9404 + 4.70935E-5 * d
        e = 0.016709 - 1.151E-9 * d
        
        // Compute true longitude and radius vector
        E = M + e.degrees * .sind(M) * ( 1.0 + e * .cosd(M) )
        x = .cosd(E) - e
        y = (1.0 - .pow(e, 2)).squareRoot() * .sind(E)
        let r = (.pow(x, 2) + .pow(y, 2)).squareRoot()  // Solar distance
        v = .atan2d(y: y, x: x)
        let lon = (v + w).firstRevolution               // True solar longitude. Needs more testing
        return (lon, r)
    }
    
    /// This function computes GMST0, the Greenwich Mean Sidereal Time
    /// at 0h UT (i.e. the sidereal time at the Greenwich meridian at
    /// 0h UT).  GMST is then the sidereal time at Greenwich at any
    /// time of the day.  I've generalised GMST0 as well, and define it
    /// as:  GMST0 = GMST - UT  --  this allows GMST0 to be computed at
    /// other times than 0h UT as well.  While this sounds somewhat
    /// contradictory, it is very practical:  instead of computing GMST like:
    ///
    ///  GMST = (GMST0) + UT * (366.2422/365.2422)
    ///
    /// where (GMST0) is the GMST last time UT was 0 hours, one simply computes:
    ///
    ///  GMST = GMST0 + UT
    ///
    /// where GMST0 is the GMST "at 0h UT" but at the current moment!
    /// Defined in this way, GMST0 will increase with about 4 min a
    /// day.  It also happens that GMST0 (in degrees, 1 hr = 15 degr)
    /// is equal to the Sun's mean longitude plus/minus 180 degrees!
    /// (if we neglect aberration, which amounts to 20 seconds of arc
    /// or 1.33 seconds of time)
     
    static func gmst0(d: Double) -> Double {
        //Sidtime at 0h UT = L (Sun's mean longitude) + 180.0 degr
        //L = M + w, as defined in sunpos()
        ((180.0 + 356.0470 + 282.9404) + (0.9856002585 + 4.70935E-5) * d).firstRevolution
    }
    
    /// Struct that describes sun altitude and whether or not centre or upper limb is used to calulate event
    public struct AstronomicalEvent {
        /// Sun altitude:
        /// `-35/60` for sunrise/sunset
        /// `-6` for civil twilight
        /// `-12` for nautical twilight
        /// `-18` for astronomical twilight
        public let sunAltitude: Double
        
        /// `true` for calculating sunset/sunrise
        public let upperLimb: Bool
        
        public static let sunriseSet = AstronomicalEvent(sunAltitude: -35/60, upperLimb: true)
        public static let civilTwilight = AstronomicalEvent(sunAltitude: -6, upperLimb: false)
        public static let nauticalTwilight = AstronomicalEvent(sunAltitude: -12, upperLimb: false)
        public static let astronomicalTwilight = AstronomicalEvent(sunAltitude: -18, upperLimb: false)
    }
}
