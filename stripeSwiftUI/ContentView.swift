//
//  ContentView.swift
//  stripeSwiftUI
//
//  Created by yujin on 2021/05/31.
//

import SwiftUI

struct ContentView: View {
    //https://developer.apple.com/forums/thread/654978
    //https://stackoverflow.com/questions/56498045/remove-extra-line-separators-below-list-in-swiftui
    @State var greeting = "Good Morning"
    @State var productListNSArray = NSArray()
    @State var items = [String]()
    @State var productIds = [String]()
    @State var skus = [String]()
    @State var prices = [String]()
    @State var images = [UIImage]()
    @State private var scale = [CGFloat]()
    let backendCheckoutUrl = URL(string: "http://192.168.179.4:3000/products")
    @State var volumes = [Int]()
    
    init() {
        
//        UITableView.appearance().separatorStyle = .none not working
    }
    
    private func configListView(){
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
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else{ return }
        DispatchQueue.main.async {
            productListNSArray = json["data"] as! NSArray
            print(productListNSArray)
            for i in 0..<productListNSArray.count {
                let jsonjson = productListNSArray[i] as? [String:Any]
                let name = jsonjson!["name"] as! String
                let id = jsonjson!["id"] as! String
                let meta = jsonjson!["metadata"] as? [String:Any]
                let price = meta!["price"] as? String
                let sku = meta!["sku"] as? String
                items.append(name)
                productIds.append(id)
                prices.append(price!)
                skus.append(sku!)
                volumes.append(0)
                scale.append(1)
                
                let image = jsonjson!["images"] as! NSArray
                let imageStr = image[0] as! String
                
                do {
                    let url = URL(string: imageStr)
                    let data = try Data(contentsOf: url!)
                    let img = UIImage(data: data)
                    images.append(img!)
                }
                catch{
                    print(error)
                    images.removeAll()
                }
            }
        }
      })
      task.resume()
    }

    var body: some View {
        let withIndex = items.enumerated().map({$0})
        
            NavigationView{
                VStack{
                    Image("johnnyAlbert").resizable().scaledToFit().frame(width: 150, height: 40, alignment: .top)
                    
                    Text("Glasses and Sunglasses").font(.system(size:20))
                    List(withIndex, id: \.element) { index,item in
                            HStack{
                                VStack(alignment: .leading){
                                if images.count > 0{
                                    Image(uiImage:images[index]).resizable().scaledToFill().frame(width:30, height:30).padding(.leading,20)
                                }
                                
                                    Text(item)
                                    
                                    Text("USD:\(prices[index])").font(.headline).foregroundColor(.red)
                                    
                                    Text("STOCK:\(skus[index])").font(.subheadline).foregroundColor(.gray)
                                    
                                    
                                }.frame(minWidth:0,maxWidth:200,alignment:.leading)
                            
                                
                                Spacer(minLength: 5)
                                Text("\(volumes[index])").font(.subheadline).foregroundColor(.gray).scaleEffect(scale[index])
                                
                                Spacer(minLength: 5)
                                Button("Add"){}
                                    .padding(5).onTapGesture {
                                    print(index)
                                    let incremented = volumes[index] + 1
                                    volumes[index] = incremented
                                        scale[index] = 2.5
                                        DispatchQueue.global(qos: .userInitiated).async {
                                        usleep(50000)
                                        scale[index] = 1.0
                                        }
                                    }
                            }
                    }.listStyle(GroupedListStyle()).frame(width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height * 0.6,alignment:.top)
                        
                    
                    NavigationLink(destination: CheckoutView(initialStr: $greeting)) {
                        Text("Checkout")
                            .frame(minWidth: 0, maxWidth: 150, minHeight:10, maxHeight:20)
                        .padding()
                        .foregroundColor(.white)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.blue]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(30)
                        .font(.title)
                    }
                    Spacer().frame(height:30)
                }.background(Color(.white))//
        }.onAppear(){configListView()}.frame(width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height * 1.0,alignment: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
