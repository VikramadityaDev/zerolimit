// // ignore_for_file: prefer_const_constructors
//
// import 'package:flutter/material.dart';
// import 'package:zerolimit/screens/upload_pic.dart';
// import 'package:zerolimit/screens/upload_vid.dart';
//
// class BottomBar extends StatefulWidget {
//   const BottomBar({super.key});
//
//   @override
//   State<BottomBar> createState() => _BottomBarState();
// }
//
// class _BottomBarState extends State<BottomBar> {
//   int currentIndex = 0;
//   final pages = [
//     const UploadPic(),
//     const UploadVideo(),
//   ];
//   void onTabTapped(int index) async {
//     setState(() {
//       currentIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: BottomNavigationBar(
//         unselectedFontSize: 12,
//         selectedFontSize: 12,
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         onTap: onTabTapped,
//         currentIndex: currentIndex,
//         selectedItemColor: Color(0XFF9B4BFF),
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true, // Show unselected labels
//         showSelectedLabels: true, // Show selected labels
//         elevation: 0,
//         items: const [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.image_rounded), label: "Upload Picture"),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.video_file_rounded), label: "Upload Video"),
//         ],
//       ),
//       body: pages[currentIndex],
//     );
//   }
// }
