//
//  RollerShutters.swift
//  VaporApp
//
//  Created by Eric on 18/10/2016.
//
//

import Foundation
import Dispatch
import Vapor
import HTTP

class RollerShuttersController
{
  //  let actionQueue = DispatchQueue(label: "RollerShuttersController.Action")
   // let actionAllQueue = DispatchQueue(label: "RollerShuttersController.ActionAll")
   // var dataStore = DataModelStore.shared
    var rollerShuttersCurrentPositions = [0,0,0,0,0]
    var rollerShuttersTargetPositions = [0,0,0,0,0]
    var rollerShuttersAreWorking = [false, false, false, false, false]
  //  enum Places: Int { case LIVING_ROOM = 0, DINING_ROOM, OFFICE, KITCHEN, BEDROOM, count }
    
    init()
    {
        for  index in 0..<rollerShuttersCurrentPositions.count
        {
            let open = self.actionCheckIfOpen(rollerShutterIndex: index) ?? false
            internalVarAccessQueue.sync {
                self.rollerShuttersCurrentPositions[index] = open ? 100 : 0
                self.rollerShuttersTargetPositions[index] = open ? 100 : 0
            }
        }
        
        drop.get("window-covering/getCurrentPosition", Int.self)
        { request, index in
            var value = 0
            internalVarAccessQueue.sync {value = self.rollerShuttersCurrentPositions[index]}
            return try JSON(node: ["value": value])
        }
        
        drop.get("window-covering/getTargetPosition", Int.self)
        { request, index in
            var value = 0
            internalVarAccessQueue.sync {value = self.rollerShuttersTargetPositions[index]}
            return try JSON(node: ["value": value])
        }
        
        drop.get("window-covering/setTargetPosition", Int.self, Int.self)
        { request, index, position in
            DispatchQueue(label: "net.emillet.domo.RollerShuttersController.\(index)").async {
                if self.rollerShuttersTargetPositions[index] != position
                {
                    let currentPos = self.rollerShuttersCurrentPositions[index]
                    let targetPos = self.rollerShuttersTargetPositions[index]
                    let isWorking = self.rollerShuttersAreWorking[index]
                    let offset = currentPos > position ? currentPos - position : position - currentPos
                    if position != targetPos && isWorking == false && offset > 15
                    {
                        self.rollerShuttersAreWorking[index] = true
                        self.rollerShuttersTargetPositions[index] = position
                        self.actionOpen(rollerShutterIndex: index, position: position )
                        self.rollerShuttersCurrentPositions[index] = position
                        self.rollerShuttersAreWorking[index] = false
                    }
                }
            }
            return try JSON(node: ["value": position])
        }

        drop.get("window-covering/getCurrentPosition/all")
        { request in
            var value = 0
            internalVarAccessQueue.sync
                {
                //    for index in 0..<Places.count.rawValue {value += self.rollerShuttersCurrentPositions[index]}
                  //  value = Int(Float(value)/Float(Places.count.rawValue))
                    value = self.rollerShuttersCurrentPositions[Places.KITCHEN.rawValue]
            }
            return try JSON(node: ["value": value])
        }
        
        drop.get("window-covering/getTargetPosition/all")
        { request in
            var value = 0
            internalVarAccessQueue.sync {value = self.rollerShuttersTargetPositions[Places.KITCHEN.rawValue]}
            return try JSON(node: ["value": value])
        }
        
        drop.get("window-covering/setTargetPosition/all", Int.self)
        { request, position in
            DispatchQueue(label: "net.emillet.domo.RollerShuttersController.All").async {
                if self.rollerShuttersTargetPositions[Places.KITCHEN.rawValue] != position
                {
                    self.actionForAllRollerShutters(position: position)
                }
            }
            return try JSON(node: ["value": self.rollerShuttersTargetPositions[0]])
        }
        
        DispatchQueue(label: "net.emilletfr.domo.ThermostatController.TimerSeconde").async
            {
                while true
                {
                    sleep(1)
                    DispatchQueue(label: "net.emilletfr.domo.Main.TimerSeconde").async {
                        let date = Date(timeIntervalSinceNow: 0)
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = TimeZone(abbreviation: "CEST")
                        dateFormatter.locale = Locale(identifier: "fr_FR")
                        dateFormatter.dateFormat =  "HH:mm:ss"
                        self.timerSeconde(date: dateFormatter.string(from: date))
                    }
                }
        }
    }
    
    func timerSeconde(date:String)
    {
        /*
       //     guard let sunriseTime = dataStore.data.sunriseTime , let sunsetTime = dataStore.data.sunsetTime else {return}
        let sunriseTime = dataStore.data.sunriseTime
        let sunsetTime = dataStore.data.sunsetTime
            if date == "\(sunriseTime):00"
            {
                log("RollerShuttersController:actionForAllRollerShutters() - now : \(date) - sunriseTime : \(sunriseTime) - sunsetTime : \(sunsetTime)")
                self.actionForAllRollerShutters(position: 100)
            }
            if date == "\(sunsetTime):00"
            {
                log("RollerShuttersController:actionForAllRollerShutters() - now : \(date) - sunriseTime : \(sunriseTime) - sunsetTime : \(sunsetTime)")
                self.actionForAllRollerShutters(position: 0)
            }
 */
    }
    
    func actionForAllRollerShutters(position:Int)
    {
        for index in 0..<Places.count.rawValue
        {
            if !(index == Places.BEDROOM.rawValue && position == 100)
            {
                self.rollerShuttersTargetPositions[index] = position
                self.actionOpen(rollerShutterIndex: index, position:position)
                self.rollerShuttersCurrentPositions[index] = position
            }
        }
    }
    
    func actionOpen(rollerShutterIndex:Int, position:Int)
    {
        do
        {
            let currentPos = self.rollerShuttersCurrentPositions[rollerShutterIndex]
            let targetPos = self.rollerShuttersTargetPositions[rollerShutterIndex]
            let open = targetPos > currentPos ? "1" : "0"
            let urlString = "http://10.0.1.1\(rollerShutterIndex)/\(open)"
            _ = try drop.client.get(urlString)
            let offset = currentPos > targetPos ? currentPos - targetPos : targetPos - currentPos
            var delay = 140000*(offset)
            if position == 0 || position == 100 {delay = 14_000_000}
            usleep(useconds_t(delay))
            _ = try drop.client.get(urlString)
            sleep(2)
        }
        catch {log(error)}
    }
    
    func actionCheckIfOpen(rollerShutterIndex:Int) -> Bool?
    {
        let urlString = "http://10.0.1.1\(rollerShutterIndex)/status"
        let response = try? drop.client.get(urlString)
        guard let localResponse = response, let json = localResponse.json, let openJson = json["open"], let open = openJson.int else {return nil}
        return open == 1
    }
}