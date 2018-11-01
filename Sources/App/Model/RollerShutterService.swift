//
//  RollerShutterService.swift
//  VaporApp
//
//  Created by Eric on 14/12/2016.
//
//

import RxSwift

final class RollerShutterService : RollerShutterServicable
{
    let currentPositionObserver = [PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>()]
    let targetPositionObserver = [PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>()]
    
    let targetPositionPublisher = [PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>(), PublishSubject<Int>()]
    
    let httpClient : HttpClientable
    
    required init(httpClient : HttpClientable = HttpClient()) {
        self.httpClient = httpClient
        self.reduce()
    }
    
    func reduce() {
        let action = PublishSubject<(Int, Int, Int)>()
        // create actions
        for placeIndex in 0..<Place.count.rawValue {
            _ = Observable.combineLatest(currentPositionObserver[placeIndex].distinctUntilChanged(), targetPositionPublisher[placeIndex].distinctUntilChanged())
                .subscribe(onNext: { (current:Int, target:Int) in
                    action.onNext((placeIndex, current, target))
                })
        }
        // concat actions
        let queue = action.concatMap { (index:Int, current:Int, target:Int) -> Observable<(Int, Int)> in
            return Observable.combineLatest(Observable.of(current), Observable.of(target))
                .flatMap({ (current:Int, target:Int) -> Observable<Int> in return self.process(index, current, target) })
                .map({ target -> (Int, Int) in return (index, target)})
                .take(1)
        }
        // action completion subscription
        _ = queue.subscribe(onNext: { (index:Int, target:Int) in
            self.currentPositionObserver[index].onNext(target)
            self.targetPositionObserver[index].onNext(target)
        })
        // Wrap to Initial State
        for placeIndex in 0..<Place.count.rawValue {
            _ = self.httpClient.send(url: "http://10.0.1.1\(placeIndex)/status", responseType: RollerShutterResponse.self)
                .map({ (r) -> Int in return r.open*100 })
                .subscribe(onNext: { (position) in
                    self.currentPositionObserver[placeIndex].onNext(position)
                    self.targetPositionObserver[placeIndex].onNext(position)
                })
        }
    }
    
    func process(_ placeIndex:Int, _ currentPosition:Int, _ targetPosition:Int) -> Observable<Int>  {
        if currentPosition == targetPosition {
            return Observable.of(targetPosition)
        }
        let open = targetPosition > currentPosition ? "1" : "0"
        let urlString = "http://10.0.1.1\(placeIndex)/\(open)"
        let offset = currentPosition > targetPosition ? currentPosition - targetPosition : targetPosition - currentPosition
        var delay : Int = Int(offset*14/100)
        if targetPosition == 0 || targetPosition == 100 {delay = 14}
        
        return self.httpClient.send(url: urlString, responseType: RollerShutterResponse.self)
            .flatMap({ _ in return secondEmitter }).skip(delay).take(1)
            .flatMap({_ in return self.httpClient.send(url: urlString, responseType: RollerShutterResponse.self)})
            .flatMap({ _ in return secondEmitter }).skip(1).take(1)
            .map({ _ in return targetPosition})
    }
    
    struct RollerShutterResponse: Decodable
    {
        let open: Int
    }
}