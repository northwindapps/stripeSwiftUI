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
  let backendCheckoutUrl = URL(string: "http://192.168.179.4:3000/checkout") // Your backend endpoint
  @Published var paymentSheet: PaymentSheet?
  @Published var paymentResult: PaymentSheetResult?
  @Published var customerId: String?
  @Published var customerEphemeralKeySecret: String?
  @Published var paymentIntentClientSecret: String?
  @Published var failedInPaymentSheet: Bool?
  init() {
    STPAPIClient.shared.publishableKey = ""
  }

    func preparePaymentSheet(customerId:String,productAry:[String],priceAry:[String],quantityAry:[Int]) {
    // MARK: Fetch the PaymentIntent and Customer information from the backend
    var request = URLRequest(url: backendCheckoutUrl!)
    
        let parameterDictionary = ["customerId":customerId,"products":productAry,"prices":priceAry,"quantities":quantityAry] as [String : Any]
    request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
    let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options:[])
    request.httpBody = httpBody
    request.httpMethod = "POST"
        
    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        if let data = data {
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            if let j = json{
            let customerId = json!["customer"] as? String
            let customerEphemeralKeySecret = json!["ephemeralKey"] as? String
            let paymentIntentClientSecret = json!["paymentIntent"] as? String
                
                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Example, Inc."
                configuration.customer = .init(id: customerId!, ephemeralKeySecret: customerEphemeralKeySecret!)

                  DispatchQueue.main.async {
                    self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret!, configuration: configuration)
                  }
                
            }else{
                // Handle error
                if let error = error{
                    print("error",error)
                }
                if let httpResponse = response as? HTTPURLResponse {
                    print("status",httpResponse.statusCode)
                }
                
                DispatchQueue.main.async {
                    self.failedInPaymentSheet = true
                    return
                }
            }
        }

    
        }).resume()
    }
    

    

    func onPaymentCompletion(result: PaymentSheetResult) {
      self.paymentResult = result
    }
}

struct CheckoutView: View {
  @ObservedObject var order = OrderClass()
  @ObservedObject var model = MyBackendModel()
  @State var skuUpdateResult = false
    
    func updatestock(newskus:[Int],productids:[String]) {
    // MARK: Fetch the PaymentIntent and Customer information from the backend
    let backendUpdateUrl = URL(string: "http://192.168.179.4:3000/products")
    var request = URLRequest(url: backendUpdateUrl!)
    
        let parameterDictionary = ["skus":newskus,"productids":productids] as [String : Any]
    request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
    let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options:[])
    request.httpBody = httpBody
    request.httpMethod = "POST"
        
    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if let httpResponse = response as? HTTPURLResponse {
                    print("status",httpResponse.statusCode)
                    DispatchQueue.main.async {
                        skuUpdateResult = true
                    }
                }
        }).resume()
    }
    
    func updateskus(){
        var newskus = [Int]()
        var productids = [String]()
        for i in 0..<order.productIds!.count {
            if order.volumes![i] > 0 {
                productids.append(order.productIds![i])
                order.skus![i]  = order.skus![i] - order.volumes![i]
                newskus.append(order.skus![i])
                order.volumes![i] = 0
            }
        }
        updatestock(newskus: newskus,productids: productids)
    }
  var body: some View {
    
    VStack {
        if skuUpdateResult{
            //why sending order here? you know there's a styling problem in the list view
            ProductView(loaded:false, checkOut:false, order:self.order)
        }else{
            Spacer()
      if let paymentSheet = model.paymentSheet {
        PaymentSheet.PaymentButton(
          paymentSheet: paymentSheet,
          onCompletion: model.onPaymentCompletion
        ) {
          Text("Buy")
        }
      } else {
        Text("Loading…").onAppear(){}
      }
        if let failed = model.failedInPaymentSheet{
            Text("Something went wrong.").onAppear(){skuUpdateResult = true}
        }
      if let result = model.paymentResult {
        switch result {
        case .completed:
            Text("Payment completed.").onAppear(){
                updateskus()
            }
        case .failed(let error):
            Text("Payment failed: \(error.localizedDescription)").onAppear(){
                DispatchQueue.global(qos: .userInitiated).async {
                    usleep(50000)
                    skuUpdateResult = true
                }
                }
        case .canceled:
            Text("Payment canceled.").onAppear(){
                DispatchQueue.global(qos: .userInitiated).async {
                    usleep(50000)
                    skuUpdateResult = true
                }
            }
        }
      }
            Spacer()
    }
      
    }.onAppear(){ model.preparePaymentSheet(customerId:order.customerId!, productAry: order.productIds!, priceAry: order.prices!, quantityAry: order.volumes!) }
    
  }
}
