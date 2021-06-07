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
    
    init(){
        customerId = ""
        productIds = [String]()
        prices = [String]()
        volumes = [Int]()
        skus = [Int]()
    }
}

class ShippingClass: ObservableObject {
    @Published var username: String?
    @Published var email: String?
    @Published var phone: String?
    @Published var zipcode: String?
    @Published var country: String?
    @Published var city: String?
    @Published var line1: String?
    @Published var line2: String?
    
    init(){
        username = ""
        email = ""
        phone = ""
        zipcode = ""
        country = ""
        city = ""
        line1 = ""
        line2 = ""
    }
}

struct ProductView: View {
    @State private var productListNSArray = NSArray()
    @State private var items = [String]()
    @State private var images = [UIImage]()
    @State var loaded = false
    @State var checkOut = false
    @State var validationPassed = false
    @State private var scale = [CGFloat]()
    @State var isEditing = false
    @ObservedObject var order = OrderClass()
    @ObservedObject var shipping = ShippingClass()
    @State var username:String = ""
    @State var email:String = ""
    @State var phone:String = ""
    @State var zipcode:String = ""
    @State var country:String = ""
    @State var city:String = ""
    @State var line1:String = ""
    @State var line2:String = ""
    
    func validate(value:String,name:String){
        enum Field:String{
            case username,email,phone,zipcode,country,city,line1,line2
        }
        
        let fieldcase = Field(rawValue: name)
        switch fieldcase {
        case .username:
            if value.count > 0{
                shipping.username = value
            }else{
                username = ""
            }
        case .email:
            if value.count > 0{
                shipping.email = value
            }else{
                email = ""
            }
        case .phone:
            let num = value.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            if Double(num) != nil{
                shipping.phone = value
            }else{
                phone = ""
            }
        case .zipcode:
            let num = value.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            if Double(num) != nil{
                shipping.zipcode = value
            }else{
                zipcode = ""
            }
        case .country:
            if value.count > 0{
                shipping.country = value
            }else{
                country = ""
            }
        case .city:
            if value.count > 0{
                shipping.city = value
            }else{
                city = ""
            }
        case .line1:
            if value.count > 0{
                shipping.line1 = value
            }else{
                line1 = ""
            }
        case .line2:
            if value.count > 0{
                shipping.line2 = value
            }else{
                line2 = ""
            }
        default:
            break
        }
    }
    
    private func validationCheck(){
        if shipping.username!.count > 0 &&
            shipping.email!.count > 0 &&
            shipping.phone!.count > 0 &&
            shipping.zipcode!.count > 0 &&
            shipping.country!.count > 0 &&
            shipping.city!.count > 0 &&
            shipping.line1!.count > 0 &&
            shipping.line2!.count > 0{
            validationPassed = true
        }
    }
    
    private func configListView(){
        print("onAppear")
        items.removeAll()
        productListNSArray = []
        images.removeAll()
        productList()
        UITableView.appearance().backgroundColor = UIColor.white
        UITableView.appearance().allowsSelection = false
    }
    
    private func productList() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        let backendCheckoutUrl = URL(string: "http://192.168.179.4:3000/products")
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
                //Assign a guestId in this course
                order.customerId = "cus_JcVVxfn4IYCjwF"
                for i in 0..<productListNSArray.count {
                    let jsonjson = productListNSArray[i] as? [String:Any]
                    let name = jsonjson!["name"] as! String
                    let id = jsonjson!["id"] as! String
                    let meta = jsonjson!["metadata"] as? [String:Any]
                    let price = meta!["price"] as? String
                    let sku = meta!["sku"] as? String
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
                    }
                    catch{
                        print(error)
                        images.removeAll()
                        loaded = false
                    }
                }
                loaded = true
            }
        })
        task.resume()
    }
    
    var body: some View {
        ScrollView(showsIndicators:false){
            VStack{
                if checkOut {
                    CheckoutView(order: self.order, shipping: self.shipping)
                }else{
                    Spacer()
                    Image("johnnyAlbert").resizable().scaledToFit().frame(width: 150, height: 40, alignment: .top)
                    
                    Text("Glasses and Sunglasses").font(.system(size:20))
                    
                    if loaded == false{
                        ProgressView()
                        Spacer()
                    }else if loaded == true{
                        let withIndex = items.enumerated().map({$0})
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
                        }.listStyle(GroupedListStyle()).frame(minWidth:UIScreen.main.bounds.size.width,maxWidth:UIScreen.main.bounds.size.width,minHeight:UIScreen.main.bounds.size.height * 0.8, maxHeight:UIScreen.main.bounds.size.height * 1.0)
                        
                        
                        
                        VStack(alignment: .center){
                            Text("Shipping Info").font(.system(size:20))
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("username",text: $username){ isEditing in self.isEditing = isEditing} onCommit: {validationCheck()}.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom).onChange(of:username){
                                    newValue in validate (value:username,name:"username")
                                }
                            }
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("email",text: $email){ isEditing in self.isEditing = isEditing} onCommit: { validationCheck()
                                }.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom).onChange(of:email){
                                    newValue in validate (value:email,name:"email")
                                }
                            }
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("phone",text: $phone){ isEditing in self.isEditing = isEditing} onCommit: { validationCheck()
                                }.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom).onChange(of:phone){
                                    newValue in validate (value:phone,name:"phone")
                                }
                            }
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("zipcode",text: $zipcode){ isEditing in self.isEditing = isEditing} onCommit: { validationCheck()
                                }.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom)
                            }.onChange(of:zipcode){
                                newValue in validate (value:zipcode,name:"zipcode")
                            }
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("country",text: $country){ isEditing in self.isEditing = isEditing} onCommit: { validationCheck()
                                }.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom).onChange(of:country){
                                    newValue in validate (value:country,name:"country")
                                }
                            }
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("city",text: $city){ isEditing in self.isEditing = isEditing} onCommit: { validationCheck()
                                }.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom).onChange(of:city){
                                    newValue in validate (value:city,name:"city")
                                }
                            }
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("line1",text: $line1){ isEditing in self.isEditing = isEditing} onCommit: { validationCheck()
                                }.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom).onChange(of:line1){
                                    newValue in validate (value:line1,name:"line1")
                                }
                            }
                            HStack{
                                Text("*").font(.largeTitle).foregroundColor(.red)
                                TextField("line2",text: $line2){ isEditing in self.isEditing = isEditing} onCommit: { validationCheck()
                                }.autocapitalization(.none).disableAutocorrection(true).frame(width: UIScreen.main.bounds.width*0.8, height: 30).border(Color(UIColor.separator)).padding(.bottom).onChange(of:line2){
                                    newValue in validate (value:line2,name:"line2")
                                }
                            }
                            if validationPassed{
                                Button("Checkout"){checkOut = true}.frame(width: 150,height:20).padding()
                                    .foregroundColor(.white)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.blue]), startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(30)
                                    .font(.title)
                            }else{
                                Spacer().frame(height:100)
                            }
                        }//loaded
                    }//checkout else
                    Spacer().frame(height:20)
                }//shipping vstack
            }//vstack
        }.onAppear(){configListView()}.frame(height:UIScreen.main.bounds.height*1.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProductView()
    }
}
