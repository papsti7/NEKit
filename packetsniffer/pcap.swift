//
//  pcap.swift
//  NEKit
//
//  Created by Stefan Papst on 05/06/2017.
//  Copyright © 2017 Zhuhao Wang. All rights reserved.
//

import Foundation

let LINKTYPE_ETHERNET : UInt32 = 1
let LINKTYPE_RAW : UInt32 = 101


let src_mac : (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB)
let dest_mac : (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0x00, 0x11, 0x22, 0x33, 0x44, 0x55)

let pcap_record_size : UInt32 = 65535
let pcap_file_size : CLong = 300 * 1024 * 1024

//file header
struct pcap_hdr_s {
    let magic_number : UInt32
    let version_major : UInt16
    let version_minor : UInt16
    let thiszone : Int32
    let sigfigs : UInt32
    let snaplen : UInt32
    let network : UInt32
};
//packet header
struct pcaprec_hdr_s {
    let ts_sec : UInt32
    let ts_usec : UInt32
    let incl_len : UInt32
    let orig_len : UInt32
};
//packet ethernet header
struct ethernet_hdr_s {
    let dhost : (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let shost : (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let type : UInt16
};
