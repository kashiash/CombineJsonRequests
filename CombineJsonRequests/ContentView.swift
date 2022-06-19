//
//  ContentView.swift
//  CombineJsonRequests
//
//  Created by Jacek Placek on 19/06/2022.
//
import Combine
import SwiftUI


struct Message: Decodable, Identifiable {
    var id: Int
    var from: String
    var message: String
}


struct ContentView: View {
    
    @State private var requests = Set<AnyCancellable>()
    @State private var messages = [Message]()
    @State private var favorites = Set<Int>()
    
    var body: some View {
        NavigationView {
            List(messages) { message in
                HStack {
                    VStack(alignment: .leading) {
                        Text(message.from)
                            .font(.headline)

                        Text(message.message)
                            .foregroundColor(.secondary)
                    }

                    if favorites.contains(message.id) {
                        Spacer()

                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Messages")
        }
        .onAppear {
            let messagesURL = URL(string: "https://www.hackingwithswift.com/samples/user-messages.json")!
            let messagesTask = fetch(messagesURL, defaultValue: [Message]())

            let favoritesURL = URL(string: "https://www.hackingwithswift.com/samples/user-favorites.json")!
            let favoritesTask = fetch(favoritesURL, defaultValue: Set<Int>())
       
          
            let combined = Publishers.Zip(messagesTask, favoritesTask)
            
            combined.sink { loadedMessages, loadedFavorites in
                messages = loadedMessages
                favorites = loadedFavorites
            }
            .store(in: &requests)
        }
    }
    
    func fetch<T: Decodable>(_ url: URL, defaultValue: T, completion: @escaping (T) -> Void) {
        let decoder = JSONDecoder()

        URLSession.shared.dataTaskPublisher(for: url)
            .retry(1)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .replaceError(with: defaultValue)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: completion)
            .store(in: &requests)
    }
    func fetch<T: Decodable>(_ url: URL, defaultValue: T) -> AnyPublisher<T, Never> {
        let decoder = JSONDecoder()

        return URLSession.shared.dataTaskPublisher(for: url)
            .delay(for: .seconds(Double.random(in: 1...5)), scheduler: RunLoop.main)  //for time shift demontration only
            .retry(1)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .replaceError(with: defaultValue)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func basicAuthTrip(didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.previousFailureCount < 3 {
            let credential = URLCredential(user: "bbbb", password: "BBBB", persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    func digestAuthTrip(didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.previousFailureCount < 3 {
            let credential = URLCredential(user: "dddd", password: "DDDD", persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // Look for specific authentication challenges and dispatch those to various helper methods.
        //
        // IMPORTANT: It's critical that, if you get a challenge you weren't expecting,
        // you resolve that challenge with `.performDefaultHandling`.

        switch (challenge.protectionSpace.authenticationMethod, challenge.protectionSpace.host) {
            case (NSURLAuthenticationMethodHTTPBasic, "httpbin.org"):
                self.basicAuthTrip(didReceive: challenge, completionHandler: completionHandler)
            case (NSURLAuthenticationMethodHTTPDigest, "httpbin.org"):
                self.digestAuthTrip(didReceive: challenge, completionHandler: completionHandler)
            default:
                completionHandler(.performDefaultHandling, nil)
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
