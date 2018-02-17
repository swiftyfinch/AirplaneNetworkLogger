//
//  AirplaneNetworkLogger.swift
//
//  Created by Vyacheslav Khorkov on 15/05/2017.
//  Copyright © 2017 Vyacheslav Khorkov. All rights reserved.
//

import Moya
import Result

final class AirplaneNetworkLogger: PluginType {
    private var requestStartDates: [URLRequest: Date] = [:]
    
    // MARK: - Format
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    private var currentDate: String {
        return dateFormatter.string(from: Date())
    }
    
    private func timeSinceRequest(_ request: URLRequest?) -> String? {
        guard let request = request,
            let startDate = requestStartDates[request] else { return nil }
        
        let timeInterval = Date().timeIntervalSince(startDate)
        let millisecondsInSecond = 1000.0
        return "\(Int(timeInterval * millisecondsInSecond)) ms"
    }
    
    private func format(type: String, message: String?) -> String {
        return "✈︎ Network (\(currentDate)) \(type): \(message ?? "none")"
    }
    
    // MARK: Confirm Protocol 
    
    func willSend(_ request: Moya.RequestType, target: TargetType) {
        guard let request = request.request else { return }
        
        requestStartDates[request] = Date()
        let url = request.url?.absoluteString.removingPercentEncoding
        print(format(type: "Request", message: url))
    }
    
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            do {
                let responseBody = try response.mapString().decodeCyrillic()
                let time = timeSinceRequest(response.request) ?? "?"
                let message = """
                (code: \(response.statusCode), dutation: \(time)):
                \(responseBody)
                """
                
                print(format(type: "Response", message: message))
            } catch { /* Ignore error */ }
        default:
            break
        }
    }
}

fileprivate extension String {
    func decodeCyrillic() -> String {
        let convertedString = (self as NSString).mutableCopy() as! NSMutableString
        let encodingTransform: NSString = "Any-Hex/Java"
        CFStringTransform(convertedString, nil, encodingTransform, true)
        return String(convertedString)
    }
}
