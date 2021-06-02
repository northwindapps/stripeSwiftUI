//
//  ShoppingView.swift
//  stripeSwiftUI
//
//  Created by yujin on 2021/05/31.
// https://stripe.com/docs/payments/accept-a-payment?platform=ios

import Stripe
import SwiftUI
//https://www.hackingwithswift.com/quick-start/swiftui/how-to-respond-to-view-lifecycle-events-onappear-and-ondisappear


class MyBackendModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://apple.com") // Your backend endpoint
  @Published var paymentSheet: PaymentSheet?
  @Published var paymentResult: PaymentSheetResult?
  @Published var customerId: String?
  @Published var customerEphemeralKeySecret: String?
  @Published var paymentIntentClientSecret: String?

  init() {
    STPAPIClient.shared.publishableKey = ""
  }

  func prepareEphemeralKeys() {
    // MARK: Fetch the PaymentIntent and Customer information from the backend
    var request = URLRequest(url: backendCheckoutUrl!)
    request.httpMethod = "POST"
    let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
            let customerId = json["customer"] as? String,
            let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
            let self = self else {return}
      DispatchQueue.main.async {
        self.customerId = customerId
        self.customerEphemeralKeySecret = customerEphemeralKeySecret
      }
    })
    task.resume()
  }

 func preparePaymentIntent() {
  // MARK: Fetch the PaymentIntent and Customer information from the backend
  var request = URLRequest(url: backendCheckoutUrl!)
  request.httpMethod = "POST"
  let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
  guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
            let paymentIntentClientSecret = json["paymentIntent"] as? String,
            let self = self else {return}
    DispatchQueue.main.async {
        self.paymentIntentClientSecret = paymentIntentClientSecret
    }
   })
   task.resume()
  }
    
  func preparePaymentSheet() {
    // MARK: Create a PaymentSheet instance
    var configuration = PaymentSheet.Configuration()
    configuration.merchantDisplayName = "Example, Inc."
    configuration.customer = .init(id: self.customerId!, ephemeralKeySecret:self.customerEphemeralKeySecret!)
    self.paymentSheet = PaymentSheet(paymentIntentClientSecret:
    self.paymentIntentClientSecret!, configuration: configuration)
  }

  func onPaymentCompletion(result: PaymentSheetResult) {
    self.paymentResult = result
  }
}

struct CheckoutView: View {
    
  @Binding var initialStr:String
  @ObservedObject var model = MyBackendModel()
  var body: some View {
    VStack {
      if let paymentSheet = model.paymentSheet {
        PaymentSheet.PaymentButton(
          paymentSheet: paymentSheet,
          onCompletion: model.onPaymentCompletion
        ) {
          Text("Buy")
        }
      } else {
        Text("Loading…")
      }
      if let result = model.paymentResult {
        switch result {
        case .completed:
          Text("Payment complete")
        case .failed(let error):
          Text("Payment failed: \(error.localizedDescription)")
        case .canceled:
          Text("Payment canceled.")
        }
      }
    }.onAppear(){print(initialStr)}
  }
}
//model.preparePaymentSheet()
