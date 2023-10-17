import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const bgColor = Color(0xfffafafa);

class ResultPage extends StatelessWidget {
  final String qrData;
  const ResultPage({required this.qrData, Key? key}) : super(key: key);

  Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    try {
      // Fetch order details from Firestore based on the scanned QR code data (orderId)
      DocumentSnapshot<Map<String, dynamic>> orderSnapshot =
          await FirebaseFirestore.instance
              .collection('Orders')
              .doc(orderId)
              .get();

      // Return the data as a Map
      return orderSnapshot.data() ?? {};
    } catch (e) {
      // Handle errors, e.g., if the orderId doesn't exist in the database
      print('Error fetching order details: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    var modeOfPayment;

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchOrderDetails(qrData.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the Future is still running, show a loading indicator
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          // If there was an error fetching data, display an error message
          return const Scaffold(
              body: Center(child: Text('Error fetching order details.')));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // If no data is found for the given orderId, display a message
          return const Scaffold(
              body: Center(
                  child: Text('No order found for the scanned QR code.')));
        } else {
          // If data is available, display the ordered items using ListView
          Map<String, dynamic> orderData = snapshot.data!;
          List<Widget> orderedItems = orderData.entries.map((entry) {
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(entry.key),
                subtitle: Text(
                    'Size: ${entry.value['Size']}, Quantity: ${entry.value['Quantity']}, Price: ${entry.value['Price']}'),
              ),
            );
          }).toList();

          // Calculate grand total
          double grandTotal = orderData.entries.fold(0, (sum, entry) {
            return sum + (entry.value['Quantity'] * entry.value['Price']);
          });

          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              title: const Text(
                "Order Details",
                style: TextStyle(color: Colors.black),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  const Text(
                    "Ordered Items",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ...orderedItems,
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total($modeOfPayment):',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹$grandTotal',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
