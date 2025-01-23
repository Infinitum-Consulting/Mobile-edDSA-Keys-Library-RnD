//
//  WebSocketConnection.swift
//  testing-ios-app-1
//
//  Created by Yash Goyal on 06/11/24.
//

import Foundation

class Websocket: ObservableObject {
    @Published var messages = [String]()
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    init() {
        self.connect()
    }
    
    private func connect() {
        guard let url = URL(string: "wss://9fbd-2405-201-6819-2010-784e-afcb-5318-7b75.ngrok-free.app") else { return }
        let request = URLRequest(url: url)
        print("h")
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        print("he")
        webSocketTask?.resume()
        print("her")
        receiveMessage()
        print("here")
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            print("Received: \(result)")
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.formatReceivedMessage(text)
                case .data(let data):
                    // Handle binary data
                    break
                @unknown default:
                    break
                }
            }
            
            self?.receiveMessage()
        }
    }
    
    func formatReceivedMessage(_ msg: String) {
        let jsonData = Data(msg.utf8)
        let decoder = JSONDecoder()

        do {
            let res = try decoder.decode(Message.self, from: jsonData)
            switch res.action {
            case "get-id":
                let data = try decoder.decode(GetIdResponse.self, from: jsonData)
                print("id", data.id)
            default :
                break
            }
            print(res)
        } catch {
            print(error.localizedDescription)
        }
        
//        self.messages.append(msg)
    }
    
    func sendMsg(_ msg: Message) {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(msg)
            let messageStr = String(data: data, encoding: .utf8)!
            
            sendMessage(messageStr)
        } catch {
            
        }
    }
    
    func sendMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}
