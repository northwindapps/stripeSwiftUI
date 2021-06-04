//
//  ContentView.swift
//  stripeSwiftUI
//
//  Created by yujin on 2021/05/31.
//

import SwiftUI

class OrderClass: ObservableObject {
    @Published var customerId: String?
    @Published var productIds : [String]?
    @Published var volumes : [Int]?
    @Published var prices : [String]?
    @Published var skus : [Int]?
    // And any other properties you want to pass back and forth.
    // Maybe even a complex Struct (which is a value type, but wrapped in a class)
}

struct ProductView: View {
    //https://developer.apple.com/forums/thread/654978
    //https://stackoverflow.com/questions/56498045/remove-extra-line-separators-below-list-in-swiftui
    
    @State var productListNSArray = NSArray()
    @State var items = [String]()
    @State var images = [UIImage]()
    @State var loaded = false
    @State var checkOut = false
    @State var scale = [CGFloat]()
    @ObservedObject var order = OrderClass()
  
    let backendCheckoutUrl = URL(string: "http://192.168.179.4:3000/products")

    
    private func configListView(){
        print("onAppear")
        productList()
        UITableView.appearance().backgroundColor = UIColor.white
        UITableView.appearance().allowsSelection = false
   
    }
    
   
    private func productList() {
      // MARK: Fetch the PaymentIntent and Customer information from the backend
      var request = URLRequest(url: backendCheckoutUrl!)
      request.httpMethod = "GET"
      request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
      let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        if let httpResponse = response as? HTTPURLResponse {
            print("status",httpResponse.statusCode)
        }
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else{ return }
        DispatchQueue.main.async {
            productListNSArray = json["data"] as! NSArray
            order.productIds = [String]()
            order.prices = [String]()
            order.volumes = [Int]()
            order.skus = [Int]()
            //Assign a guestId in this course
            order.customerId = "cus_JbMVtpRmUNtzVt"
            for i in 0..<productListNSArray.count {
                let jsonjson = productListNSArray[i] as? [String:Any]
                let name = jsonjson!["name"] as! String
                let id = jsonjson!["id"] as! String
                let meta = jsonjson!["metadata"] as? [String:Any]
                let price = meta!["price"] as? String
                let sku = meta!["sku"] as? String
                print("sku",sku)//not updated soon.
                items.append(name)
                order.productIds!.append(id)
                order.prices!.append(price!)
                order.skus!.append(Int(sku!)!)
                order.volumes!.append(0)
                scale.append(1)
                let image = jsonjson!["images"] as! NSArray
                let imageStr = image[0] as! String
                do {
                    let url = URL(string: imageStr)
                    let data = try Data(contentsOf: url!)
                    let img = UIImage(data: data)
                    images.append(img!)
                    loaded = true
                }
                catch{
                    print(error)
                    images.removeAll()
                    loaded = false
                }
            }
        }
      })
      task.resume()
    }

    var body: some View {
                VStack{
                    if checkOut {
                        CheckoutView(order: self.order)
                    }else{
                    let withIndex = items.enumerated().map({$0})
                    Spacer()
                    Image("johnnyAlbert").resizable().scaledToFit().frame(width: 150, height: 40, alignment: .top)
                    
                    Text("Glasses and Sunglasses").font(.system(size:20))
                    if loaded == false{
                        
                        ProgressView()
                        Spacer()
                    }
//                    if loaded{
                        List(withIndex, id: \.element) { index,item in
                            HStack{
                                VStack(alignment: .leading){
                                if images.count > 0{
                                    Image(uiImage:images[index]).resizable().scaledToFill().frame(width:30, height:30).padding(.leading,20)
                                }
                                
                                    Text(item)
                                    
                                    Text("USD:\(order.prices![index])").font(.headline).foregroundColor(.red)
                                    
                                    Text("STOCK:\(order.skus![index])").font(.subheadline).foregroundColor(.gray)
                                    
                                    
                                }.frame(minWidth:0,maxWidth:200,alignment:.leading)
                            
                                
                                Spacer(minLength: 5)
                                Text("\(order.volumes![index])").font(.subheadline).foregroundColor(.gray).scaleEffect(scale[index])
                                
                                Spacer(minLength: 5)
                            
                                Button("Add"){}
                                    .padding(5).onTapGesture {
                                        print(index)
                                        
                                        var incremented = order.volumes![index] + 1
                                        if incremented > order.skus![index]{
                                            incremented = 0
                                        }
                                        order.volumes![index] = incremented
                                        scale[index] = 2.5
                                        DispatchQueue.global(qos: .userInitiated).async {
                                        usleep(50000)
                                        scale[index] = 1.0
                                    }
                                }
                            }
                        }.listStyle(GroupedListStyle()).frame(width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height * 0.6,alignment:.top)
//                    }
                    if loaded{
                        Spacer().frame(height:20)
                        Button("Checkout"){checkOut = true}
                            .frame(minWidth: 0, maxWidth: 150, minHeight:10, maxHeight:20)
                        .padding()
                        .foregroundColor(.white)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.blue]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(30)
                            .font(.title)
                        
                        Spacer()
                        }
                    }
                }.onAppear(){configListView()}.frame(width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height * 1.0,alignment: .top)
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProductView()
    }
}
