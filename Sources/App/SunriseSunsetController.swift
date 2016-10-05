//
//  SunriseSunsetManager.swift
//  VaporApp
//
//  Created by Eric on 25/09/2016.
//
//

import Foundation
import Dispatch
import Vapor
import HTTP

class SunriseSunsetController
{
    let serialQueue = DispatchQueue(label: "net.emilletfr.domo.SunriseSunsetManager.Internal")
    private var sunriseTimeInternalValue : String?
    var sunriseTime : String? {
        get {return serialQueue.sync { sunriseTimeInternalValue }}
        set (newValue) {serialQueue.sync { sunriseTimeInternalValue = newValue}}
    }
    private var sunsetTimeInternalValue : String?
    var sunsetTime : String? {
        get {return serialQueue.sync { sunsetTimeInternalValue }}
        set (newValue) {serialQueue.sync { sunsetTimeInternalValue = newValue}}
    }
    private var client: ClientProtocol.Type

    
    init(droplet:Droplet)
    {
        
        
        self.client = droplet.client
        DispatchQueue(label: "net.emilletfr.domo.SunriseSunsetManager.Timer").async
            {
                while true
                {
                    self.retrieveSunriseSunset()
                    sleep(3600)
                }
        }
        
        droplet.get("sunriseTime") { request in
            guard let sunriseTime = self.sunriseTime else {let res = try Response(status: .badRequest, json:  JSON(node:[])); return res}
            return String(describing: sunriseTime)
        }
        
        droplet.get("sunsetTime") { request in
            guard let sunsetTime = self.sunsetTime else {let res = try Response(status: .badRequest, json:  JSON(node:[])); return res}
            return String(describing: sunsetTime)
        }

        
    }
    
    
    func actionRollingShutters(openOrClose:Bool)
    {
        DispatchQueue(label: "net.emilletfr.domo.SunriseSunsetManager.Action").async
            {
                let state = openOrClose ? "0" : "1"
                for index in 1...4
                {
                    if index == 3
                    {
                        let stateLocal = openOrClose ? "1" : "0"
                        let urlString = "http://10.0.1.12/\(stateLocal)"
                        _ = try? self.client.get(urlString)
                        print("Ouvrir volets : \(state)")
                        sleep(13)
                    }
                    else
                    {
                    let urlString = "http://10.0.1.200/preset.htm?led\(index)=\(state)"
                    _ = try? self.client.get(urlString)
                    print("Ouvrir volets : \(state)")
                    sleep(13)
                    }
                }
        }
    }
    
    
    func timerSeconde (date:String)
    {
        if let sunriseTime = self.sunriseTime , let sunsetTime = self.sunsetTime
        {
            if date == "\(sunriseTime):00" {self.actionRollingShutters(openOrClose: true)}
            if date == "\(sunsetTime):00" {self.actionRollingShutters(openOrClose: false)}
        }
    }


    func retrieveSunriseSunset()
    {
        let urlString = "http://api.sunrise-sunset.org/json?lat=48.556&lng=6.401&date=today&formatted=0"
         let response = try? self.client.get(urlString)
        guard let sunriseDateStr = response?.data["results", "sunrise"]?.string else {return}
        guard let sunsetDateStr = response?.data["results", "sunset"]?.string else {return}
        let iso8601DateFormatter = DateFormatter()
        iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
        iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
         guard let sunsetDate = iso8601DateFormatter.date(from: sunsetDateStr), let sunriseDate = iso8601DateFormatter.date(from: sunriseDateStr) else {return}
        let localDateformatter = DateFormatter()
        localDateformatter.timeZone = TimeZone(abbreviation: "CEST") // "CEST": "Europe/Paris"
        localDateformatter.dateFormat = "HH:mm"
        self.sunsetTime = localDateformatter.string(from: sunsetDate)
        self.sunriseTime = localDateformatter.string(from: sunriseDate)
        if let sunrise = self.sunriseTime {print("sunriseTime : \(sunrise)")}
        if let sunset = self.sunsetTime {print("sunsetTime : \(sunset)")}

        
   /*
        URLSession.shared.dataTask(with: url!, completionHandler: { (data:Data?, response:URLResponse?,error: Error?) in
            
            guard let dataResp = data,
                let json = try? JSONSerialization.jsonObject(with: dataResp, options: .mutableContainers),
                let jsonDict = json as? [String:Any],
                let results = jsonDict["results"] as? [String:Any],
                let sunset = results["sunset"],
                let sunrise = results["sunrise"] else {print("----------error"); return}
            
            if #available(OSX 10.12, *)
            {
                let dateFormatter = ISO8601DateFormatter()
                let tz = TimeZone(abbreviation: "CEST") // "CEST": "Europe/Paris"
                dateFormatter.timeZone = tz
                let sunsetDate = dateFormatter.date(from: (sunset as! String))
                let sunriseDate = dateFormatter.date(from: (sunrise as! String))
                
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                self.sunsetTime = formatter.string(from: sunsetDate!)
                self.sunriseTime = formatter.string(from: sunriseDate!)
                if let sunrise = self.sunriseTime {print("sunriseTime : \(sunrise)")}
                if let sunset = self.sunsetTime {print("sunsetTime : \(sunset)")}
      /*
                let sunsetTimeInterval = sunsetDate?.timeIntervalSinceNow
                if let sunsetTimeInterval = sunsetTimeInterval
                {
                    if sunsetTimeInterval > 0
                    {
                        self.sunsetTimer?.cancel()
                        self.sunsetTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos:.background))
                        self.sunsetTimer?.scheduleOneshot(deadline: DispatchTime.init(secondsFromNow:sunsetTimeInterval))
                        self.sunsetTimer?.setEventHandler(handler: self.sunsetWorkItem)
                        self.sunsetTimer?.resume()
                    }
                }
                
                let sunriseTimeInterval = sunriseDate?.timeIntervalSinceNow
                if let sunriseTimeInterval = sunriseTimeInterval
                {
                    if sunriseTimeInterval > 0
                    {
                        self.sunriseTimer?.cancel()
                        self.sunriseTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos:.background))
                        self.sunriseTimer?.scheduleOneshot(deadline: DispatchTime.init(secondsFromNow:sunriseTimeInterval))
                        self.sunriseTimer?.setEventHandler(handler: self.sunriseWorkItem)
                        self.sunriseTimer?.resume()
                    }
                }
                 */
            }
            else { }
        }).resume()
         */
    }
    /*
    func sunriseWorkItem()
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        print(formatter.string(from: Date(timeIntervalSinceNow: 0 )))
        print(self.sunriseTime)
    }
    
    func sunsetWorkItem ()
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        print(formatter.string(from: Date(timeIntervalSinceNow: 0 )))
        print(self.sunsetTime)
    }
 */
    



}
/*
class ISO8601DateFormatterLinux: DateFormatter {
    
    static let sharedDateFormatter = ISO8601DateFormatterLinux()
    
    override init() {
        super.init()
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)!
    }
    
}
*/




