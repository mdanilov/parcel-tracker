//
//  MoyaposylkaService.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 24/11/2018.
//  Copyright © 2018 Maxim Danilov. All rights reserved.
//

import Foundation

let sharedMoyaposylkaService = MoyaposylkaService()

class MoyaposylkaService {
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    typealias QueryResult = ([Carrier]) -> ()
    
    func requestCarrier(_ barcode: String, completion: @escaping QueryResult) {
        // GET https://moyaposylka.ru/api/v1/carriers/{barcode}
        guard let url = URL(string: "https://moyaposylka.ru/api/v1/carriers/\(barcode)") else {
            return
        }

        print("Info: Request carriers for \(barcode): GET \(url)")

        func updateModel(_ data: Data, _ carriers: inout [Carrier]) {
            guard let model = try? JSONDecoder().decode([Carrier].self, from: data) else {
                print("Error: Couldn't decode data into Carriers")
                return
            }
            print("Info: Got updated carrier list \(model)")
            carriers = model
        }
        
        dataTask?.cancel()
        var carriers: [Carrier] = []
        
        dataTask = defaultSession.dataTask(with: url) { data, response, error in
            defer { self.dataTask = nil }
            if let error = error {
                print("Error: DataTask error, " + error.localizedDescription)
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                updateModel(data, &carriers)
            }
            
            DispatchQueue.main.async {
                completion(carriers)
            }
        }
        
        dataTask?.resume()
    }
    
    typealias RequestStatusQueryResult = (ParcelStatus?) -> ()
    
    func doGetRequest(_ query: Query, _ carrier: String, _ barcode: String, _ numberOfAttemps: Int, _ completion: @escaping RequestStatusQueryResult) {
        // GET https://moyaposylka.ru/api/v1/trackers/{carrier}/{barcode}/realtime
        let url = URL(string: "https://moyaposylka.ru/api/v1/trackers/\(carrier)/\(barcode)/realtime")!
        print("Info: Get status for \(carrier), \(barcode): GET \(url)")
        
        let task = defaultSession.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: DataTask error, " + error.localizedDescription)
            } else if let data = data,
                let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.millisecondsSince1970
                    guard let result = try? decoder.decode(ParcelStatus.self, from: data) else {
                        print("Error: Couldn't decode data into Parcel")
                        return
                    }
                    print("Info: Got updated parcel status \(result)")
                    completion(result)
                } else if (response.statusCode == 404) {
                    let data: AnyObject = try! JSONSerialization.jsonObject(with: data, options:.mutableContainers) as AnyObject
                    if (data["message"] as! String == "RealtimeRequestNotFound") {
                        completion(nil)
                    } else if (data["message"] as! String == "RealtimeRequestNotReady" && numberOfAttemps > 0) {
                        print("Warning: Parcel status is not ready yet, try to request again")
                        DispatchQueue.main.async {
                            if (query.running) {
                                query.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                                    self.doGetRequest(query, carrier, barcode, numberOfAttemps - 1, completion)
                                }
                            }
                        }
                    }
                } else {
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    func doPostRequest(_ query: Query, _ carrier: String, _ barcode: String, _ pin: String?, _ completion: @escaping RequestStatusQueryResult) {
        // POST https://moyaposylka.ru/api/v1/trackers/{carrier}/{barcode}/realtime
        let url = URL(string: "https://moyaposylka.ru/api/v1/trackers/\(carrier)/\(barcode)/realtime")!
        print("Info: Request status for \(carrier), \(barcode): POST \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if (carrier == "jde") {
            let parameters = ["pin": pin ?? ""]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                completion(nil)
            }
        }
        
        let task = defaultSession.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: DataTask error, " + error.localizedDescription)
            } else if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.doGetRequest(query, carrier, barcode, 5, completion)
                }
                else {
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    class Query {
        var timer: Timer?
        var running: Bool = true
        
        func cancel() {
            running = false
            if (timer != nil) {
                timer!.invalidate()
            }
        }
    }
    
    func requestParcelStatus(_ carrier: String, _ barcode: String, _ pin: String?, completion: @escaping RequestStatusQueryResult) -> Query {
        let query = Query()
        doGetRequest(query, carrier, barcode, 1) { parcelStatus in
            if parcelStatus == nil {
                self.doPostRequest(query, carrier, barcode, pin, completion)
            } else {
                completion(parcelStatus)
            }
        }
        return query
    }
}
