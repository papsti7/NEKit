//
//  pcapObject.swift
//  NEKit
//
//  Created by Stefan Papst on 05/06/2017.
//  Copyright © 2017 Zhuhao Wang. All rights reserved.
//

import Foundation

class PcapObject {

    let filename = "\(Date().description).pcap"
    var pcapHeader : pcap_hdr_s = pcap_hdr_s(magic_number: 0xa1b2c3d4, version_major: 2, version_minor: 4, thiszone: 0, sigfigs: 0, snaplen: pcap_record_size, network: LINKTYPE_ETHERNET)
    var pcapPackets : [PcapPacket] = []
    
    public func writeToFile() {
        guard let logsURL = PcapObject.createProjectDirectoryPath(path: "pcapFiles") else {
            fatalError("Cannot create directory")
        }
        let urlToFile = logsURL.appendingPathComponent(filename)
        guard let ostream = OutputStream(url: urlToFile, append: false) else {
            fatalError("Cannot open file")
        }
        ostream.open()
        //write pcapFile header
        let headerSize = MemoryLayout.size(ofValue: pcapHeader)
        
        let bytesWritten = withUnsafePointer(to: &pcapHeader) {
            $0.withMemoryRebound(to: UInt8.self, capacity: headerSize) {
                ostream.write($0, maxLength: headerSize)
            }
        }
        if bytesWritten != headerSize {
            // Could not write all bytes, report error ...
            NSLog("12345- error in Writting, not all Bytes written: bytesWritten: %d|headersize: %d", bytesWritten, headerSize)
        }
        NSLog("444- going to write %d packets", pcapPackets.count)
        //write pcapPackets
        pcapPackets.forEach { (packet) in
            NSLog("444- packet++")
            NSLog("12345- going to write packets")
            //packet header
            let headerSize = MemoryLayout.size(ofValue: packet.pcapHeader)
            NSLog("12345- got headersize: %d", headerSize)
            var bytesWritten = withUnsafePointer(to: &(packet.pcapHeader)) {
                $0.withMemoryRebound(to: UInt8.self, capacity: headerSize) {
                    ostream.write($0, maxLength: headerSize)
                }
            }
            if bytesWritten != headerSize {
                // Could not write all bytes, report error ...
                NSLog("12345- error in Writting packet header, not all Bytes written: bytesWritten: %d|headersize: %d", bytesWritten, headerSize)
            }
            NSLog("12345- Wrote packet header")
            //ethernet header
            let ethernetheaderSize = MemoryLayout.size(ofValue: packet.ethernetHeader)
            
            NSLog("12345- got ethernetheadersize: %d", ethernetheaderSize)
            assert(ethernetheaderSize == 14)
            bytesWritten = withUnsafePointer(to: &(packet.ethernetHeader)) {
                $0.withMemoryRebound(to: UInt8.self, capacity: ethernetheaderSize) {
                    ostream.write($0, maxLength: ethernetheaderSize)
                }
            }
            if bytesWritten != ethernetheaderSize {
                // Could not write all bytes, report error ...
                NSLog("12345- error in Writting ethernetheader, not all Bytes written: bytesWritten: %d|ethernetheaderSize: %d", bytesWritten, ethernetheaderSize)
            }
            NSLog("12345- Wrote ethernet header")
            
            
            let data = Data(packet.payload)
            
            _ = data.withUnsafeBytes {
                ostream.write($0, maxLength: data.count)
            }
            
        

            NSLog("12345- Wrote packet payload")
        }
        NSLog("12345- Finished writing")
        ostream.close()
    }
    
    static func createProjectDirectoryPath(path:String) -> URL? {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.at.tugraz.iospacketsniffer")
        let logsURL = containerURL!.appendingPathComponent(path)
        do {
            try FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)
        } catch let error as NSError {
            NSLog("Unable to create directory %@", error.debugDescription)
            return nil
        }
        return logsURL
    }
    
}
