
import NEKit
import CocoaLumberjackSwift
import NetworkExtension



class PacketTunnelProvider: NEPacketTunnelProvider, NWUDPSocketDelegate {
    var interface: TUNInterface!
    // Since tun2socks is not stable, this is recommended to set to false
    var enablePacketProcessing = true
    var session : NWUDPSocket?
    var proxyPort: Int!
    var tcpconnection: NWTCPConnection?
    var proxyServer: ProxyServer!
    var sessionToProxyServer: NWUDPSession?
    

    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        NSLog("startTunnel")
        proxyPort = 9090
        
        RawSocketFactory.TunnelProvider = self
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = 1500
        
        let ipv4Settings = NEIPv4Settings(addresses: ["129.27.229.118"], subnetMasks: ["255.255.255.0"])
//        ipv4Settings.includedRoutes = [NEIPv4Route(destinationAddress: "5.35.243.23", subnetMask: "255.255.255.0")]
        if enablePacketProcessing {
            ipv4Settings.includedRoutes = [NEIPv4Route.default()]
            ipv4Settings.excludedRoutes = [
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            ]
            //            self.session = NWUDPSocket(host: "127.0.0.1", port: self.proxyPort)
            
        }
        
        networkSettings.iPv4Settings = ipv4Settings
        
        //        let proxySettings = NEProxySettings()
        //        proxySettings.autoProxyConfigurationEnabled = true
        //        proxySettings.proxyAutoConfigurationJavaScript = "function FindProxyForURL(url, host) {return \"SOCKS 127.0.0.1:\(proxyPort)\";}"
        //        proxySettings.httpEnabled = true
        //        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        //        proxySettings.httpsEnabled = true
        //        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        //        proxySettings.excludeSimpleHostnames = true
        // This will match all domains
        //        proxySettings.matchDomains = [""]
        //        networkSettings.proxySettings = proxySettings
        
        // the 198.18.0.0/15 is reserved for benchmark.
        if enablePacketProcessing {
            let DNSSettings = NEDNSSettings(servers: ["198.18.0.1"])
            DNSSettings.matchDomains = [""]
            DNSSettings.matchDomainsNoSearch = false
            networkSettings.dnsSettings = DNSSettings
        }
        
        setTunnelNetworkSettings(networkSettings) {
            error in
            guard error == nil else {
                DDLogError("Encountered an error setting up the network: \(String(describing: error))")
                completionHandler(error)
                return
            }
            self.proxyServer = GCDSOCKS5ProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
            //            self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
            try! self.proxyServer.start()
            
            
            self.tcpconnection = self.createTCPConnection(to: NWHostEndpoint(hostname: "127.0.0.1", port: "9090"), enableTLS: false, tlsParameters: nil, delegate: nil)
            
            
            
            completionHandler(nil)
            //        self.writePackets()
//            self.readPackets()
            
            if self.enablePacketProcessing {
                self.interface = TUNInterface(packetFlow: self.packetFlow)
                
                var fakeIPPool : IPPool?
                do {
                    fakeIPPool = try IPPool(range: IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!))
                }
                catch {
                    print(error)
                }
                
                let dnsServer = DNSServer(address: IPAddress(fromString: "198.18.0.1")!, port: Port(port: 53), fakeIPPool: fakeIPPool!)
                let resolver = UDPDNSResolver(address: IPAddress(fromString: "114.114.114.114")!, port: Port(port: 53))
                dnsServer.registerResolver(resolver)
                self.interface.register(stack: dnsServer)
                DNSServer.currentServer = dnsServer
                
                let udpStack = UDPDirectStack()
                self.interface.register(stack: udpStack)
                
                
                let tcpStack = TCPStack.stack
                tcpStack.proxyServer = self.proxyServer
                self.interface.register(stack: tcpStack)
                
                self.interface.start()
                
                
            }
            
        }
        
        
        
    }
    func readPackets() {
        
        self.packetFlow.readPackets { (data, number) in
            NSLog("-------")
            var content : String = ""
            
            data.map{
                self.tcpconnection?.write($0, completionHandler: { (error) in
                    let error = error.debugDescription ?? "nil"
                    NSLog("error in write data to tcp connection %@", error)
                })
                $0.map{
                    content += " \(String(format:"%2X", $0))"
                }
                //self.sessionToProxyServer?.writeDatagram($0, completionHandler: { (error) in
                //   NSLog("error in write to proxy session: \(error)")
                //                })
            }
            
            NSLog("%@", content)
            self.readPackets()
        }
    }
    
    
    func writePackets() {
        self.sessionToProxyServer?.setReadHandler({ (_packets: [Data]?, error: Error?) -> Void in
            if let packets = _packets {
                // This is where decrypt() should reside, I just omit it like above
                self.packetFlow.writePackets(packets, withProtocols: [NSNumber](repeating: AF_INET as NSNumber, count: packets.count))
            }
        }, maxDatagrams: NSIntegerMax)
    }
    
    
    
    func didReceive(data: Data, from: NWUDPSocket) {
        NSLog("received")
    }
    func didCancel(socket: NWUDPSocket) {
        NSLog("testcancel")
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        if enablePacketProcessing {
            interface.stop()
            interface = nil
            DNSServer.currentServer = nil
        }
        
        proxyServer.stop()
        proxyServer = nil
        RawSocketFactory.TunnelProvider = nil
        
        completionHandler()
        
        // For unknown reason, the extension will be running for several extra seconds, which prevents us from starting another configuration immediately. So we crash the extension now.
        // I do not find any consequences.
        exit(EXIT_SUCCESS)
    }
    
    
}
