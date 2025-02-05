import SwiftUI
import uFCoder

class APDUCommandViewWrapper: ObservableObject {
    @Published var alertMessage = ""
    
    @Published var showAlertFlag = false
    @Published var alertTitle = ""
    @Published var alertCaption = ""
    
    @Published var isConnected: Bool = false
    @Published var isCardPresent: Bool = false
    
}

struct APDUCommandView: View {
    
    @StateObject private var viewWrapper = APDUCommandViewWrapper()
    
    @State private var is_nfc = false
    
    @State private var apduCommand: String = "<CUSTOM>"
    @State private var serialNumber: String = "ON105733"
    @State private var outputLog: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App Title
            Text("uFR APDU Example v1.0")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            VStack {
                HStack{
                    Text("uFR Online serial number:")
                        .font(.headline)
                        .frame(width:210, alignment: .leading)
                    Spacer()
                    TextField("Enter serial number", text: $serialNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 130)
                        .focused($isTextFieldFocused)
                }
                HStack {
                    // Action Button
                    Button(action: {
                        // Simulate sending the APDU command
                        doReaderOpen()
                    }) {
                        Text("BLE Session Open")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewWrapper.isConnected ? Color.green : Color.red)
                            .cornerRadius(8)
                    }
                }
                
            }
            
            // Input Field for APDU Commands
            VStack(alignment: .leading) {
                Text("Enter APDU Command:")
                    .font(.headline)
                TextField("e.g 90 6E 00 00 00", text: $apduCommand)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)
            }

            // Output Log
            VStack(alignment: .leading) {
                Text("Output Log:")
                    .font(.headline)
                ScrollView {
                    Text(outputLog.isEmpty ? "No output yet." : outputLog)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        //.background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 200) // Limit log height
            }

            // Action Button
            Button(action: {
                getFirmware()
            }) {
                Text("Send Command (Get Firmware)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewWrapper.isCardPresent ? Color.green : Color.red)
                    .cornerRadius(8)
            }
            Button(action: {
                getSerialNum()
            }) {
                Text("Send Command (Get Serial#)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewWrapper.isCardPresent ? Color.green : Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
        .alert(isPresented: $viewWrapper.showAlertFlag) {
            showAlert(title: viewWrapper.alertTitle, caption: viewWrapper.alertCaption)
        }
    }
    
    private func doReaderOpen() {
        let session_context = Unmanaged.passUnretained(viewWrapper).toOpaque()
        
        let cardDetectedCallback: CardDetectedCallback = { context, uid, card_type, manufacturer in
            print("Card detected")
            DispatchQueue.main.async {
                let viewWrapper = Unmanaged<APDUCommandViewWrapper>.fromOpaque(context).takeUnretainedValue()
                viewWrapper.isCardPresent = true
            }
        }

        let cardRemovedCallback: CardRemovedCallback = { context in
            print("Card was removed")
            DispatchQueue.main.async {
                let viewWrapper = Unmanaged<APDUCommandViewWrapper>.fromOpaque(context).takeUnretainedValue()
                viewWrapper.isCardPresent = false
            }
        }
        
        let errorCallback: SessionErrorCallback = { context, status, message in
            print(String(cString: message!))
            print(status)
            DispatchQueue.main.async {
                let viewWrapper = Unmanaged<APDUCommandViewWrapper>.fromOpaque(context).takeUnretainedValue()
                viewWrapper.alertTitle = "Session error."
                viewWrapper.alertCaption = "Status: " + String(cString: UFR_SessionStatus2String(status))
                viewWrapper.showAlertFlag = true
                
                if status.rawValue >= 0 && status.rawValue <= 4 {
                    viewWrapper.isConnected = false
                }
            }
        }
        
        let status = openBLESession(session_context, serialNumber, 0, cardDetectedCallback, cardRemovedCallback, errorCallback)
        if (status == UFR_OK) {
            viewWrapper.alertTitle = "Reader Open was successful!"
            viewWrapper.alertCaption = ""
            viewWrapper.showAlertFlag = true
            viewWrapper.isConnected = true
        } else {
            viewWrapper.alertTitle = "Reader Open failed."
            viewWrapper.alertCaption = "Status: " + String(cString: UFR_Status2String(status))
            viewWrapper.showAlertFlag = true
            viewWrapper.isConnected = false
        }
        
    }

//    private func sendAPDUCommand() {
//        
//        if (!viewWrapper.isCardPresent) {
//            viewWrapper.alertTitle = "No card."
//            viewWrapper.alertCaption = "Please place a card in the readers field."
//            viewWrapper.showAlertFlag = true
//            return
//        }
//        
//        let str_apdu = apduCommand.removeNonHex()
//        if ((str_apdu.count % 2) != 0) {
//            viewWrapper.alertTitle = "Invalid input."
//            viewWrapper.alertCaption = "Please enter an even number of hex digits."
//            viewWrapper.showAlertFlag = true
//        }
//        
//        // TODO: Remove str_apdu after testing
//        let str_apdu_cust = "00A4040009A00000030800001000"
//        //let capdu = str_apdu.hexa
//        let capdu = str_apdu_cust.hexa
//        
//        let clen: UInt32 = UInt32(capdu.count)
//        var rapdu = [UInt8](repeating: 0x00, count: 256)
//        var rlen: UInt32 = 0
//        let status = APDUPlainTransceive(capdu, clen, &rapdu, &rlen)
//        let statusStr = String(cString: UFR_Status2String(status))
//        print("APDUPlainTransceive() status: \(statusStr)")
//        print(statusStr)
//        
//        if (status == UFR_OK)
//        {
//            outputLog += "Sent: \(apduCommand)\nReceived: \(rapdu.bytesToHex(spacing: ":", length: rlen))\n"
//        } else {
//            viewWrapper.alertTitle = "APDU command failed."
//            viewWrapper.alertCaption = "Status: " + String(cString: UFR_Status2String(status))
//            viewWrapper.showAlertFlag = true
//        }
//        
//        outputLog += "--------------------------\n"
//    }
    
    func getSerialNum() {
        var uFRErrorCode = UFCODER_ERROR_CODES(UFR_COMMAND_NOT_SUPPORTED.rawValue)
        
        // SELECT APDU Command
        let selectStr = "00A4040009A00000030800001000"
        let capdu1 = selectStr.hexa
        
        let clen1: UInt32 = UInt32(capdu1.count)
        var rapdu1 = [UInt8](repeating: 0x00, count: 256)
        var rlen1: UInt32 = 0
        let selStatus = APDUPlainTransceive(capdu1, clen1, &rapdu1, &rlen1)
        let selStatusStr = String(cString: UFR_Status2String(selStatus))
        print("APDUPlainTransceive() SELECT status: \(selStatusStr)")
        outputLog += "Sent: \(selectStr)\nReceived (SELECTStatus): \(rapdu1.bytesToHex(spacing: ":", length: rlen1))\n\n"
        if (selStatus == UFR_OK)
        {
            // Get Serial Number APDU Command
            let getSerial = "00f80000"
            let capdu2 = getSerial.hexa
            
            let clen2: UInt32 = UInt32(capdu2.count)
            var rapdu2 = [UInt8](repeating: 0x00, count: 256)
            var rlen2: UInt32 = 0
            let serialStatus = APDUPlainTransceive(capdu2, clen2, &rapdu2, &rlen2)
            let serialStatusStr = String(cString: UFR_Status2String(serialStatus))
            print("APDUPlainTransceive() getSerial status: \(serialStatusStr)")
            outputLog += "Sent: \(serialStatusStr)\nReceived (serialNumStatus): \(rapdu2.bytesToHex(spacing: ":", length: rlen2))\n\n"
            outputLog += "YubiKey Serial #: \(hexStringToDecimalStr(from: rapdu2.bytesToHex(spacing: ":", length: rlen2)))"
            print(outputLog)
        } else {
            viewWrapper.alertTitle = "APDU command failed."
            viewWrapper.alertCaption = "Status: " + String(cString: UFR_Status2String(selStatus))
            viewWrapper.showAlertFlag = true
        }
        print(outputLog)
    }
    
    func getFirmware() {
        var uFRErrorCode = UFCODER_ERROR_CODES(UFR_COMMAND_NOT_SUPPORTED.rawValue)
        
        // SELECT APDU Command
        let selectStr = "00A4040009A00000030800001000"
        let capdu1 = selectStr.hexa
        
        let clen1: UInt32 = UInt32(capdu1.count)
        var rapdu1 = [UInt8](repeating: 0x00, count: 256)
        var rlen1: UInt32 = 0
        let selStatus = APDUPlainTransceive(capdu1, clen1, &rapdu1, &rlen1)
        let selStatusStr = String(cString: UFR_Status2String(selStatus))
        print("APDUPlainTransceive() SELECT status: \(selStatusStr)")
        outputLog += "Sent: \(selectStr)\nReceived (SELECTStatus): \(rapdu1.bytesToHex(spacing: ":", length: rlen1))\n\n"
        print(outputLog)
        if (selStatus == UFR_OK)
        {
            // pin # 123456
            // Verify PIN APDU Command
            let verifyPinStr = "0020008008313233343536ffff"
            let capdu2 = verifyPinStr.hexa
            
            let clen2: UInt32 = UInt32(capdu2.count)
            var rapdu2 = [UInt8](repeating: 0x00, count: 256)
            var rlen2: UInt32 = 0
            let pinStatus = APDUPlainTransceive(capdu2, clen2, &rapdu2, &rlen2)
            let pinStatusStr = String(cString: UFR_Status2String(pinStatus))
            print("APDUPlainTransceive() verifyPin status: \(pinStatusStr)")
            outputLog += "Sent: \(verifyPinStr)\nReceived (pinStatus): \(rapdu2.bytesToHex(spacing: ":", length: rlen2))\n\n"
            print(outputLog)
            if (pinStatus == UFR_OK)
            {
                // Get Firmware APDU Command
                let firmwareStr = "00fd0000"
                let capdu3 = firmwareStr.hexa
                
                let clen3: UInt32 = UInt32(capdu3.count)
                var rapdu3 = [UInt8](repeating: 0x00, count: 256)
                var rlen3: UInt32 = 0
                let firmwareStatus = APDUPlainTransceive(capdu3, clen3, &rapdu3, &rlen3)
                let firmwareStatusStr = String(cString: UFR_Status2String(firmwareStatus))
                print("APDUPlainTransceive() getFirmware status: \(firmwareStatusStr)")
                if (firmwareStatus == UFR_OK)
                {
                    outputLog += "Sent: \(firmwareStr)\nReceived (firmwareStatus): \(rapdu3.bytesToHex(spacing: ":", length: rlen3))\n\n"
                } else {
                    viewWrapper.alertTitle = "APDU command failed."
                    viewWrapper.alertCaption = "Status: " + String(cString: UFR_Status2String(firmwareStatus))
                    viewWrapper.showAlertFlag = true
                }
                //outputLog = "Sent: \(firmwareStr)\nReceived: \(rapdu3.bytesToHex(spacing: ":", length: rlen3))\n\n"
                outputLog += "Firmware Version: \(processFirmwareString(rapdu3.bytesToHex(spacing: ":", length: rlen3)))"
                print(outputLog)
                outputLog += "\n--------------------------\n"
            }
        }
    }
    
    func processFirmwareString(_ input: String) -> String {
        var components = input.split(separator: ":").map(String.init)
        
        // Ensure there are at least two colons to remove from the second-to-last position
        if components.count > 2 {
            components.removeSubrange((components.count - 2)...)
        }
        
        var modifiedString = components.joined().replacingOccurrences(of: "0", with: ".")
        
        // Remove the first character if it's '.'
        if let firstChar = modifiedString.first, firstChar == "." {
            modifiedString.removeFirst()
        }
        
        // Remove all colons
        modifiedString = modifiedString.replacingOccurrences(of: ":", with: "")
        
        return modifiedString
    }
    
    func hexStringToDecimalStr(from hexInput: String) -> String {
        var components = hexInput.split(separator: ":").map(String.init)
        
        // Ensure there are at least two colons to remove from the second-to-last position
        if components.count > 2 {
            components.removeSubrange((components.count - 2)...)
        }
        
        // Join back into a single hex string
        let cleanedString = components.joined()
        
        // converting to decimal
        guard let decimalVal = UInt64(cleanedString, radix: 16) else {
            return ""
        }
        
        return String(decimalVal)
    }
    
    // Utility function to create an Alert
    func showAlert(title: String, caption: String) -> Alert {
        return Alert(
            title: Text(title),
            message: Text(caption),
            dismissButton: .default(Text("OK"), action: {
                viewWrapper.alertTitle = ""
                viewWrapper.alertCaption = ""
                viewWrapper.showAlertFlag = false
            })
            
        )
    }
}



/*
struct APDUCommandView_Previews: PreviewProvider {
    static var previews: some View {
        APDUCommandView()
    }
}
*/

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        return stride(from: 0, to: count, by: 2).compactMap { _ in
            let endIndex = index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

extension String {
    func removeNonHex() -> String {
        return self.filter { "0123456789ABCDEF".contains($0.uppercased()) }
    }
}

extension Array where Element == UInt8 {
    func bytesToHex(spacing: String, length: UInt32) -> String {
        var hexString: String = ""
        
        for byte in 0...length-1
        {
            hexString.append(String(format:"%02X", self[Int(byte)]))
            hexString.append(spacing)
        }
        
        hexString.removeLast()
        
        
        return hexString
    }
    
}

