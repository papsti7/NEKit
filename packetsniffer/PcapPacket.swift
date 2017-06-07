//
//  pcapPacket.swift
//  NEKit
//
//  Created by Stefan Papst on 05/06/2017.
//  Copyright © 2017 Zhuhao Wang. All rights reserved.
//

import Foundation
class PcapPacket {
    var pcapHeader: pcaprec_hdr_s
    var ethernetHeader : ethernet_hdr_s
    var payload : [UInt8]
    
    init(withHeader header: pcaprec_hdr_s, withEthernetHeader ethernetHeader: ethernet_hdr_s, withPayload payload: Data) {
        self.pcapHeader = header
        self.ethernetHeader = ethernetHeader
        self.payload = [UInt8](payload)
//        var string = ""
//        payload.forEach({ string += String(format: "%2X ", $0) })
        
    }
    
}
