
import NEKit
import CocoaLumberjackSwift
import NetworkExtension



class PacketTunnelProvider: NEPacketTunnelProvider, NWUDPSocketDelegate, PacketFlowDelegate{
    var interface: TUNInterface!
    // Since tun2socks is not stable, this is recommended to set to false
    var enablePacketProcessing = true
    var session : NWUDPSocket?
    var proxyPort: Int!
    var tcpconnection: NWTCPConnection?
    var proxyServer: ProxyServer!
    var sessionToProxyServer: NWUDPSession?
    var pcapObject : PcapObject = PcapObject()

    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        
        NSLog("12345- startTunnel")
        
        proxyPort = 9090
        
        RawSocketFactory.TunnelProvider = self
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = 1500
        
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.15"], subnetMasks: ["255.255.255.0"])
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
        
                let proxySettings = NEProxySettings()
//                proxySettings.autoProxyConfigurationEnabled = true
//                proxySettings.proxyAutoConfigurationJavaScript = "function FindProxyForURL(url, host) {return \"SOCKS 127.0.0.1:\(proxyPort)\";}"
                proxySettings.httpEnabled = true
                proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
                proxySettings.httpsEnabled = true
                proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
                proxySettings.excludeSimpleHostnames = true
//         This will match all domains
                proxySettings.matchDomains = [""]
                networkSettings.proxySettings = proxySettings
        
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
//            self.proxyServer = GCDSOCKS5ProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
            self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
            try! self.proxyServer.start()
            
            
            self.tcpconnection = self.createTCPConnection(to: NWHostEndpoint(hostname: "127.0.0.1", port: "9090"), enableTLS: false, tlsParameters: nil, delegate: nil)
            
            
            
            completionHandler(nil)
            //        self.writePackets()
//            self.readPackets()
            
            if self.enablePacketProcessing {
                self.interface = TUNInterface(packetFlow: self.packetFlow)
                self.interface.packetFlowDelegate = self
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

    
    func didReceive(data: Data, from: NWUDPSocket) {
        NSLog("received")
    }
    func didCancel(socket: NWUDPSocket) {
        NSLog("testcancel")
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        if enablePacketProcessing {
            self.pcapObject.writeToFile()
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
    
    func didReadPacketsFromTun(_ packets: [Data], withVersions versions: [NSNumber]) {
        NSLog("12345- packets read")
        packets.forEach ({
            var ts : timespec = timespec()
            if #available(iOSApplicationExtension 10.0, *) {
                NSLog("12345- timespec available")
                clock_gettime(_CLOCK_REALTIME, &ts)
                NSLog("12345- Got timespecs")
                NSLog("12345- ts.sec:%d ts.nsec:%d", ts.tv_sec, ts.tv_nsec)
            } else {
                // Fallback on earlier versions
                ts.tv_sec = 1000
                ts.tv_nsec = 1000 * ts.tv_sec
            }

            var length : UInt32 = UInt32($0.count)
            
            let ethernetHeader : ethernet_hdr_s = ethernet_hdr_s(dhost: dest_mac, shost: src_mac, type: 0x0008)
            
            length += 14 // sizeof(struct ethernet_hdr_s)
            
            let plen : UInt32 = (length < pcap_record_size ? length : pcap_record_size);
            let pcapRecHeader : pcaprec_hdr_s = pcaprec_hdr_s(ts_sec: UInt32(ts.tv_sec), ts_usec: UInt32(ts.tv_nsec / 1000), incl_len: plen, orig_len: length)
            let payload : NSData = NSData(data: $0)
            NSLog("12345- payload: %@",payload)
            self.pcapObject.pcapPackets.append(PcapPacket(withHeader: pcapRecHeader, withEthernetHeader: ethernetHeader, withPayload: $0))
        })
        
        
    }
    
    func didWritePacketsToTun(_ packets: [Data], withVsersions versions: [NSNumber]) {
        NSLog("12345- packet wrote")
    }
    

    
}

extension OutputStream {
    
    enum ValueWriteError: Error {
        case incompleteWrite
        case unknownError
    }
    
    func write<T>(value: T) throws {
        var value = value
        let size = MemoryLayout.size(ofValue: value)
        let bytesWritten = withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                write($0, maxLength: size)
            }
        }
        if bytesWritten == -1 {
            throw streamError ?? ValueWriteError.unknownError
        } else if bytesWritten != size {
            throw ValueWriteError.incompleteWrite
        }
    }
}

extension InputStream {
    
    enum ValueReadError: Error {
        case incompleteRead
        case unknownError
    }
    
    func read<T>(value: inout T) throws {
        let size = MemoryLayout.size(ofValue: value)
        let bytesRead = withUnsafeMutablePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                read($0, maxLength: size)
            }
        }
        if bytesRead == -1 {
            throw streamError ?? ValueReadError.unknownError
        } else if bytesRead != size {
            throw ValueReadError.incompleteRead
        }
    }
}

