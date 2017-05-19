//
//  ViewController.swift
//  NEPacketTunnelVPNDemo
//
//  Created by lxd on 12/8/16.
//  Copyright © 2016 lxd. All rights reserved.
//

import UIKit
import NetworkExtension
import NEKit



class ViewController: UIViewController{
    var vpnManager: NETunnelProviderManager = NETunnelProviderManager()
    var connectButton: UIButton!
    let packetFlowByteFileUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("packetFlowOutputByte.txt")
    let packetFlowHexFileUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("packetFlowOutputHex.txt")
    let packetFlowHexToAsciiFileUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("packetFlowHexToAsciiFileUrl.txt")
    //    // Hard code VPN configurations
    let tunnelBundleId = "at.tugraz.iospacketsniffer.tunnel"
    let serverAddress = "5.35.243.23"
    let serverPort = "54345"
    let mtu = "1400"
    let ip = "10.8.0.2"
    let subnet = "255.255.255.0"
    let dns = "8.8.4.4"
    
    
    private func initVPNTunnelProviderManager() {
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            if let error = error {
                print(error)
            }
            
            if let savedManagers = savedManagers {
                if savedManagers.count > 0 {
                    self.vpnManager = savedManagers[0]
                }
            }
            
            self.vpnManager.loadFromPreferences(completionHandler: { (error:Error?) in
                if let error = error {
                    print(error)
                }
                
                let providerProtocol = NETunnelProviderProtocol()
                providerProtocol.providerBundleIdentifier = self.tunnelBundleId
                
                providerProtocol.providerConfiguration = ["port": self.serverPort,
                                                          "server": self.serverAddress,
                                                          "ip": self.ip,
                                                          "subnet": self.subnet,
                                                          "mtu": self.mtu,
                                                          "dns": self.dns
                ]
                providerProtocol.serverAddress = self.serverAddress
                self.vpnManager.protocolConfiguration = providerProtocol
                self.vpnManager.localizedDescription = "NEPacketTunnelVPNDemoConfig"
                self.vpnManager.isEnabled = true
                
                self.vpnManager.saveToPreferences(completionHandler: { (error:Error?) in
                    if let error = error {
                        print(error)
                    } else {
                        print("Save successfully")
                    }
                })
                self.VPNStatusDidChange(nil)
                
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        GCDSOCKS5ProxyServer(address: IPAddress(fromString: "127.0.0.1"), port:9090)
        
        // Do any additional setup after loading the view, typically from a nib.
        initVPNTunnelProviderManager()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.VPNStatusDidChange(_:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func VPNStatusDidChange(_ notification: Notification?) {
        print("VPN Status changed:")
        let status = self.vpnManager.connection.status
        switch status {
        case .connecting:
            print("Connecting...")
            connectButton.setTitle("Disconnect", for: .normal)
            break
        case .connected:
            print("Connected...")
            connectButton.setTitle("Disconnect", for: .normal)
            break
        case .disconnecting:
            print("Disconnecting...")
            break
        case .disconnected:
            print("Disconnected...")
            connectButton.setTitle("Connect", for: .normal)
            break
        case .invalid:
            print("Invliad")
            break
        case .reasserting:
            print("Reasserting...")
            break
        }
    }
    
    @IBAction func go(_ sender: UIButton, forEvent event: UIEvent) {
        print("Go!")
        
        self.vpnManager.loadFromPreferences { (error:Error?) in
            if let error = error {
                print(error)
            }
            if (sender.title(for: .normal) == "Connect") {
                do {
                    try self.vpnManager.connection.startVPNTunnel()
                    //self.deleteDocumentsFolderFiles(Extension: "txt")
                } catch {
                    print(error)
                }
            } else {
                self.vpnManager.connection.stopVPNTunnel()
                /*let packetFLowCount : Int? = (UserDefaults(suiteName: "group.com.codefluegel.stefanpapst.iospacketsniffer")?.integer(forKey: "PacketFlowCount"))
                 var packetFlowData : [Data?] = [Data?]()
                 for i in 0...(packetFLowCount! - 1) {
                 let key: String = "PacketFlowData\(i)"
                 packetFlowData.append((UserDefaults(suiteName: "group.com.codefluegel.stefanpapst.iospacketsniffer")?.data(forKey: key)))
                 }
                 
                 
                 //                (packetFlowData as NSArray).write(to: self.packetFlowFileUrl, atomically: true)
                 //Todo: write to file
                 //print("sniffed data:\(packetFlowData)")
                 var packetFlowDataByteString : String = ""
                 var packetFlowDataHexString : String = ""
                 var packetFlowDataHexToAsciiString : String = ""
                 for data in packetFlowData {
                 var bytes: String = ""
                 var hexBytes: String = ""
                 for byte in data! {
                 bytes.append(" \(byte.description)")
                 hexBytes.append(" \(String(format:"%2X", byte))")
                 }
                 packetFlowDataByteString.append("\(bytes)\n")
                 packetFlowDataHexString.append("\(hexBytes)\n")
                 packetFlowDataHexToAsciiString.append("\(hexBytes)\n")
                 }
                 do {
                 try packetFlowDataByteString.write(to: self.packetFlowByteFileUrl, atomically: true, encoding: String.Encoding.ascii)
                 try packetFlowDataHexString.write(to: self.packetFlowHexFileUrl, atomically: true, encoding: String.Encoding.ascii)
                 try packetFlowDataHexToAsciiString.write(to: self.packetFlowHexToAsciiFileUrl, atomically: true, encoding: .ascii)
                 
                 self.doRequest(content: packetFlowDataHexString)
                 }
                 catch {
                 print(error)
                 }*/
            }
        }
    }
    func deleteDocumentsFolderFiles(Extension: String) {
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let directoryUrls = try  FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            //print(directoryUrls)
            let Files = directoryUrls.filter{ $0.pathExtension == Extension }.map{ $0.lastPathComponent }
            print("\(Extension) FILES:\n" + Files.description)
            for urls in directoryUrls {
                try FileManager.default.removeItem(atPath: urls.path)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func doRequest(content: String)  {
        var request = URLRequest(url: URL(string: "http://5.35.243.23:1234")!)
        request.httpMethod = "POST"
        let postString = content
        request.httpBody = postString.data(using: .ascii)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        task.resume()
    }
}




