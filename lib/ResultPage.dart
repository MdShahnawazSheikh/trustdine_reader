import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';

const bgColor = Color(0xfffafafa);

class ResultPage extends StatelessWidget {
  final String qrData;
  ResultPage({required this.qrData, Key? key}) : super(key: key);

  bool hasNavigated = false;
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

  Future<void> markOrderFulfilled(String orderId) async {
    try {
      // Fetch order details from Firestore
      DocumentSnapshot<Map<String, dynamic>> orderSnapshot =
          await FirebaseFirestore.instance
              .collection('Orders')
              .doc(orderId)
              .get();

      // Get the order data as a Map
      Map<String, dynamic> orderData = orderSnapshot.data() ?? {};

      // Loop through each item and update the "fulfilled" field to 'yes'
      orderData.forEach((key, value) {
        if (value is Map<String, dynamic> &&
            value.containsKey('fulfilled') &&
            value['fulfilled'] == 'no') {
          value['fulfilled'] = 'yes';
        }
      });

      // Update the order data in Firestore
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update(orderData);

      Fluttertoast.showToast(msg: 'Order marked as fulfilled successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error marking order as fulfilled: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String orderFulfilled = "";
    /* showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text("This Order is already fulfilled."),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Go Back")),
          TextButton(onPressed: () {}, child: Text("See Details")),
        ],
      ),
    ); */
    final TextThemeRef = Theme.of(context).textTheme;
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchOrderDetails(qrData.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the Future is still running, show a loading indicator
          return Scaffold(
              body: Center(
                  child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/illustrations/loading_plane.json',
                  repeat: true,
                ),
                SizedBox(height: 10),
                Text(
                  "Connecting to server...",
                  style: TextThemeRef.headline6,
                )
              ],
            ),
          )));
        } else if (snapshot.hasError) {
          // If there was an error fetching data, display an error message
          return Scaffold(
              body: Padding(
            padding: EdgeInsets.all(18.0),
            child: Column(
              children: [
                Lottie.asset(
                  'assets/illustrations/error_robot.json',
                  repeat: true,
                ),
                SizedBox(height: 10),
                Text('Error fetching order details.'),
              ],
            ),
          ));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // If no data is found for the given orderId, display a message
          return Scaffold(
              body: Center(
                  child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset("assets/illustrations/not_found_ufo.json"),
                SizedBox(height: 10),
                Text(
                  'No order found for the scanned QR.',
                  textAlign: TextAlign.center,
                  style: TextThemeRef.headline6,
                ),
              ],
            ),
          )));
        } else {
          // If data is available, display the ordered items using ListView
          Map<String, dynamic> orderData = snapshot.data!;
          String modeOfPayment = "";
          List<Widget> orderedItems = orderData.entries.map((entry) {
            modeOfPayment = entry.value['payment mode'];
            orderFulfilled = entry.value['fulfilled'];
            return Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: ListTile(
                title: Text(entry.key),
                subtitle: Text(
                    'Size: ${entry.value['Size']}, Quantity: ${entry.value['Quantity']}, Price: ${entry.value['Price']}'),
              ),
            );
          }).toList();

          // Calculate grand total
          double grandTotal = orderData.entries.fold(0, (sum, entry) {
            return sum + (entry.value['Price']);
          });

          return orderFulfilled == "yes"
              ? Scaffold(
                  body: Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            "assets/illustrations/error_cricle.json",
                            repeat: false,
                          ),
                          Text(
                            "This order has already been fulfilled!",
                            style: TextThemeRef.headline6,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () {
                              if (!hasNavigated) {
                                hasNavigated = true;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        backgroundColor: bgColor,
                                        appBar: AppBar(
                                          backgroundColor: Colors.transparent,
                                          centerTitle: true,
                                          title: const Text(
                                            "Order Details",
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          actions: [
                                            orderFulfilled == 'no'
                                                ? IconButton(
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return CupertinoAlertDialog(
                                                            title: const Text(
                                                                'Confirm Marking Order as Fulfilled'),
                                                            content: const Text(
                                                                'Are you sure you want to mark this order as fulfilled?'),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                style: TextButton
                                                                    .styleFrom(
                                                                        foregroundColor:
                                                                            Colors.black),
                                                                child: const Text(
                                                                    'Cancel'),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                              ),
                                                              TextButton(
                                                                style: TextButton
                                                                    .styleFrom(
                                                                        foregroundColor:
                                                                            Colors.red),
                                                                child: const Text(
                                                                    'Confirm'),
                                                                onPressed: () {
                                                                  // Call the function to mark the order as fulfilled
                                                                  markOrderFulfilled(
                                                                      qrData
                                                                          .toString());
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                    icon: Icon(
                                                      Icons.delete_forever,
                                                      color:
                                                          Colors.red.shade800,
                                                    ))
                                                : Container()
                                          ],
                                        ),
                                        body: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: ListView(
                                            children: [
                                              Text(
                                                "Order fulfilled: $orderFulfilled",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline6
                                                    ?.copyWith(
                                                        color: orderFulfilled ==
                                                                'no'
                                                            ? Colors.green
                                                            : Colors.red),
                                              ),
                                              Text(
                                                "Mode of Payment: $modeOfPayment\nOrdered Items:",
                                                style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 16),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              ...orderedItems,
                                            ],
                                          ),
                                        ),
                                        bottomNavigationBar:
                                            SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            // color: Colors.white,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Grand Total ($modeOfPayment):  ',
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Text(
                                                  '₹ $grandTotal',
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ));
                              }
                            },
                            child: Text("See Details"),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Scaffold(
                  backgroundColor: bgColor,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                    title: const Text(
                      "Order Details",
                      style: TextStyle(color: Colors.black),
                    ),
                    actions: [
                      orderFulfilled == 'no'
                          ? IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CupertinoAlertDialog(
                                      title: const Text(
                                          'Confirm Marking Order as Fulfilled'),
                                      content: const Text(
                                          'Are you sure you want to mark this order as fulfilled?'),
                                      actions: <Widget>[
                                        TextButton(
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.black),
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.red),
                                          child: const Text('Confirm'),
                                          onPressed: () {
                                            // Call the function to mark the order as fulfilled
                                            markOrderFulfilled(
                                                qrData.toString());
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: Icon(
                                Icons.delete_forever,
                                color: Colors.red.shade800,
                              ))
                          : Container()
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ListView(
                      children: [
                        Text(
                          "Order fulfilled: $orderFulfilled",
                          style: Theme.of(context)
                              .textTheme
                              .headline6
                              ?.copyWith(
                                  color: orderFulfilled == 'no'
                                      ? Colors.green
                                      : Colors.red),
                        ),
                        Text(
                          "Mode of Payment: $modeOfPayment\nOrdered Items:",
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 16),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ...orderedItems,
                      ],
                    ),
                  ),
                  bottomNavigationBar: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      // color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total ($modeOfPayment):  ',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            '₹ $grandTotal',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        }
      },
    );
  }
}
