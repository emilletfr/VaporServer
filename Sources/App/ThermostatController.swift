//
//  ThermostatController.swift
//  VaporApp
//
//  Created by Eric on 17/10/2016.
//
//


import Foundation
import Dispatch
import Vapor
import HTTP

class ThermostatController
{
    var thermostatTargetTemperature : Double = 10.0
    var thermostatMode = "auto"
    private var client: ClientProtocol.Type
    var repeatTimer: DispatchSourceTimer?
    var urlSession : URLSession?
    var indoorTempController : IndoorTempController?
    var indoorTemperature : Double = 10.0
    
    init(droplet:Droplet)
    {
        self.client = droplet.client
        self.indoorTempController = IndoorTempController(droplet: droplet)
        
        self.indoorTempController?.retrieveTemp(completion: { (temperature :Double) in
            self.indoorTemperature = temperature
        })
        
        self.repeatTimer?.cancel()
        self.repeatTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos:.background))
        self.repeatTimer?.scheduleRepeating(deadline: DispatchTime.init(secondsFromNow:1), interval: DispatchTimeInterval.seconds(10))
        self.repeatTimer?.setEventHandler(handler: self.refresh)
        self.repeatTimer?.resume()
        
        droplet.get("thermostat/status") { request in
            return try JSON(node: [
                "targetTemperature":self.thermostatTargetTemperature,
                "temperature": self.indoorTemperature ,
                "humidity":"0",
                "thermostat": self.thermostatMode
                ])
         }
        
        droplet.get("thermostat/targetTemperature", String.self) { request, temperature in
            print(temperature)
            self.thermostatTargetTemperature = Double(temperature) ?? 10.0
            self.refresh()
            return temperature
        }
        
        droplet.get("thermostat", String.self) { request, mode in
            print(mode) // off / comfort / comfort-minus-two / auto
            self.thermostatMode = mode
            self.refresh()
            return self.thermostatMode
        }
    }
    
    func refresh()
    {
        self.indoorTempController?.retrieveTemp(completion: { (indoorTemperature :Double) in
            self.indoorTemperature = indoorTemperature
            self.forceHeaterOnOrOff(heaterOnOrOff: true)
            self.forcePompOnOrOff(pompOnOrOff: indoorTemperature < self.thermostatTargetTemperature)
        })
    }
    
    func forceHeaterOnOrOff(heaterOnOrOff:Bool)
    {
        let urlString = "http://10.0.1.15:8015/0" + (heaterOnOrOff ? "1" : "0")
        let sessionConfiguration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration:sessionConfiguration)
        self.urlSession?.dataTask(with: URL(string:urlString)!) { (data:Data?, response:URLResponse?, error:Error?) in  }
    }
    
    
    func forcePompOnOrOff(pompOnOrOff:Bool)
    {
        let urlString = "http://10.0.1.15:8015/1" + (pompOnOrOff ? "1" : "0")
        let sessionConfiguration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration:sessionConfiguration)
        self.urlSession?.dataTask(with: URL(string:urlString)!) { (data:Data?, response:URLResponse?, error:Error?) in }
    }

    
    
}