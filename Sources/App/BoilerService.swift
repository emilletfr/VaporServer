//
//  BoilerService.swift
//  VaporApp
//
//  Created by Eric on 15/01/2017.
//
//

import Vapor
import Foundation
import Dispatch
import HTTP
import RxSwift

protocol BoilerServicable
{
    func forceHeater(OnOrOff:Bool)
    func forcePomp(OnOrOff:Bool)
    init(httpClient:HttpClientable)
}

class BoilerService : BoilerServicable
{
    
    var httpClient : HttpClientable!
    
    required init(httpClient:HttpClientable = HttpClient())
    {
        self.httpClient = httpClient
    }
    
    func forceHeater(OnOrOff:Bool)
    {
           _ = self.httpClient.sendGet(url: "http://10.0.1.15:8015/0" + (OnOrOff == true ? "1" : "0"))
    }
    
    func forcePomp(OnOrOff:Bool)
    {
        _ = self.httpClient.sendGet(url: "http://10.0.1.15:8015/1" + (OnOrOff == true ? "1" : "0"))
     }

}