//
//  pcap.h
//  NEKit
//
//  Created by Stefan Papst on 05/06/2017.
//  Copyright © 2017 Zhuhao Wang. All rights reserved.
//

#ifndef pcap_h
#define pcap_h

#include <Foundation/Foundation.h>

UInt32 LINKTYPE_ETHERNET = 1;
UInt32 LINKTYPE_RAW = 101;


UInt8 src_mac[6] = {0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB};
UInt8 dest_mac[6] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55};

UInt32 pcap_record_size = 65535;
long pcap_file_size = 300 * 1024 * 1024;

//file header
struct pcap_hdr_s {
    UInt32 magic_number;
    UInt16 version_major;
    UInt16 version_minor;
    int32_t thiszone;
    UInt32 sigfigs;
    UInt32 snaplen;
    UInt32 network;
};
//packet header
struct pcaprec_hdr_s {
    UInt32 ts_sec;
    UInt32 ts_usec;
    UInt32 incl_len;
    UInt32 orig_len;
};
//packet ethernet header
struct ethernet_hdr_s {
    UInt8 dhost[6];
    UInt8 shost[6];
    UInt16 type;
};


#endif /* pcap_h */






