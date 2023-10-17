import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:typed_data';

import 'package:trustdine_reader/ResultPage.dart';

const bgColor = Color(0xfffafafa);

class QrScanner extends StatelessWidget {
  const QrScanner({Key? key});

  @override
  Widget build(BuildContext context) {
    bool isResultPageOpen = false;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Order Scanner",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Place QR in the space below",
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "You will be redirected automatically",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: MobileScanner(
                // fit: BoxFit.contain,
                onDetect: (capture) {
                  if (!isResultPageOpen) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String qrData = barcodes.first.rawValue.toString();
                      isResultPageOpen =
                          true; // Set flag to true to prevent multiple windows
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultPage(qrData: qrData),
                        ),
                      ).then((value) {
                        isResultPageOpen =
                            false; // Reset the flag when the result page is closed
                      });
                    }
                  }
                },
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  "Developed as a part of TrustDine Suite",
                  style: TextStyle(
                      color: Colors.black87, fontSize: 14, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
