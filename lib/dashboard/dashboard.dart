import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_gestion_docu/dashboard/logs.dart';
import 'package:app_gestion_docu/dashboard/sidemenu.dart';
import 'package:app_gestion_docu/dashboard/identify.dart';
import 'package:app_gestion_docu/dashboard/document.dart' hide IconButton;
import 'package:app_gestion_docu/dashboard/notification.dart';
import 'package:app_gestion_docu/dashboard/contacts_screen.dart';

void main() =>
    runApp(MaterialApp(home: T6Dashboard(), debugShowCheckedModeBanner: false));

class T6Dashboard extends StatefulWidget {
  @override
  _T6DashboardState createState() => _T6DashboardState();
}

class _T6DashboardState extends State<T6Dashboard> {
  int selectedIndex = -1;
  bool _switch = false;

  final user = FirebaseAuth.instance.currentUser;

  Widget tabItem(
    BuildContext context,
    int index,
    String iconPath,
    String label,
    Widget page, {
    Widget? badgeWidget,
  }) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: const Color.fromARGB(255, 255, 198, 10),
                  width: 2,
                )
              : null,
          color: isSelected
              ? const Color.fromARGB(255, 252, 252, 252)
              : Colors.white,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: Colors.black,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (badgeWidget != null)
              Positioned(right: 0, top: 0, child: badgeWidget),
          ],
        ),
      ),
    );
  }

  Widget chatTab(BuildContext context, int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: user?.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        Widget? badgeWidget;
        if (unreadCount > 0) {
          badgeWidget = Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return tabItem(
          context,
          index,
          'assets/icons/chat.svg',
          'Chat',
          ContactsScreen(),
          badgeWidget: badgeWidget,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: T1SideMenu(),
      appBar: AppBar(
        title: const Text("Doc-Geste"),
        backgroundColor: const Color.fromARGB(255, 255, 198, 10),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Switch(
            value: _switch,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: Colors.white,
            inactiveTrackColor: Colors.black,
            onChanged: (val) {
              setState(() {
                _switch = val;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/dc.jpg"),
            fit: BoxFit.cover,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 198, 10),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tabItem(
              context,
              1,
              'assets/icons/camera.svg',
              'Identify',
              FaceGestureCameraScreen(),
            ),
            tabItem(
              context,
              0,
              'assets/icons/document.svg',
              'Document',
              DocumentManagementScreen(),
            ),
            tabItem(
              context,
              2,
              'assets/icons/logs.svg',
              'Logs',
              AccessHistoryScreen(),
            ),
            chatTab(context, 3), // 🔥 Chat avec compteur non lus
            tabItem(
              context,
              4,
              'assets/icons/notification.svg',
              'Notification',
              NotificationPage(),
            ),
          ],
        ),
      ),
    );
  }
}
