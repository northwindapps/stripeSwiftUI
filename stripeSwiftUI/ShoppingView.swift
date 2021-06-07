//
//  ShoppingView.swift
//  stripeSwiftUI
//
//  Created by yujin on 2021/05/31.

import Stripe
import SwiftUI

class MyBackendModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "http://192.168.179.4:3000/checkout") // Your backend endpoint
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var customerId: String?
    @Published var customerEphemeralKeySecret: String?
    @Published var paymentIntentClientSecret: String?
    @Published var failedInPaymentSheet: Bool?
    init() {
        STPAPIClient.shared.publishableKey = "pk_test_YOUR_PRIVATE_API_TEST_KEY"
    }
    
    func preparePaymentSheet(customerId:String,productAry:[String],priceAry:[String],quantityAry:[Int],name:String,phone:String,email:String,zipcode:String,country:String,city:String,line1:String,line2:String) {
        var request = URLRequest(url: backendCheckoutUrl!)
        let parameterDictionary = ["customerId":customerId,"products":productAry,"prices":priceAry,"quantities":quantityAry,"name":name,"phone":phone,"email":email,"zipcode":zipcode,"country":country,"city":city,"line1":line1,"line2":line2] as [String : Any]
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
    @ObservedObject var shipping = ShippingClass()
    @ObservedObject var model = MyBackendModel()
    @State var skuUpdateResult = false
    @State var failureResult = false
    
    func updatestock(newskus:[Int],productids:[String]) {
        let backendUpdateUrl = URL(string: "http://192.168.179.4:3000/products/skus")
        var request = URLRequest(url: backendUpdateUrl!)
        let parameterDictionary = ["skus":newskus,"productIds":productids] as [String : Any]
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options:[])
        request.httpBody = httpBody
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                print("status",httpResponse.statusCode)
                DispatchQueue.main.async {
                    usleep(5000000)
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
                let updatedsku  = order.skus![i] - order.volumes![i]
                newskus.append(updatedsku)
            }
        }
        updatestock(newskus: newskus,productids: productids)
    }
    var body: some View {
        VStack {
            if skuUpdateResult{
                ProductView(loaded:false, checkOut:false)
            }else if failureResult{
                ProductView(loaded:false, checkOut:false, username: self.shipping.username!, email:self.shipping.email!, phone:self.shipping.phone!, zipcode: self.shipping.zipcode!, country: self.shipping.country!, city: self.shipping.city!,line1: self.shipping.line1!,line2: self.shipping.line2! )
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
                    Text("Something went wrong.").onAppear(){failureResult = true}
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
                                failureResult = true
                            }
                        }
                    case .canceled:
                        Text("Payment canceled.").onAppear(){
                            DispatchQueue.global(qos: .userInitiated).async {
                                usleep(50000)
                                failureResult = true
                            }
                        }
                    }
                }
                Spacer()
            }
        }.onAppear(){ model.preparePaymentSheet(customerId:order.customerId!, productAry: order.productIds!, priceAry: order.prices!, quantityAry: order.volumes!,name: shipping.username!,phone: shipping.phone!,email: shipping.email!,zipcode: shipping.zipcode!,country: shipping.country!,city: shipping.city!,line1: shipping.line1!,line2: shipping.line2!) }.frame(height:UIScreen.main.bounds.height*1.0)
    }
}
