import 'package:flutter/material.dart';
import 'createPost.dart';
import 'profile.dart';
import 'homepage.dart';
import 'feed.dart';

void main() {
  runApp(MaterialApp(
    home: HomeNavigator(),
  ));
}

class HomeNavigator extends StatefulWidget {
  @override
  _HomeNavigator createState() => _HomeNavigator();
}

class _HomeNavigator extends State<HomeNavigator> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController after widget creation
    _tabController = TabController(length: 3, vsync: this);

    // Listen for tab change events to update the UI
    _tabController.addListener(() {
      setState(() {}); // Redraw the widget when the tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of the TabController when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 247, 249, 242),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color.fromARGB(255, 145, 221, 207),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('images/1_nobg.png', height: 150),
              IconButton(
                icon: Icon(Icons.logout, size: 30),
                color: Color.fromRGBO(47, 47, 47, 1),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Homepage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Link TabBarView with TabController
        children: [
          Feed(),  // Feed page
          CreatePostPage(),     // Create post page
          ProfilePage(),        // Profile page
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 145, 221, 207),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(
                Icons.home,
                size: 30,
                color: _tabController.index == 0
                    ? Color.fromARGB(255, 241, 158, 210)
                    : Color.fromARGB(255, 247, 249, 242),
              ),
            ),
            Tab(
              icon: Icon(
                Icons.add_circle,
                size: 30,
                color: _tabController.index == 1
                    ? Color.fromARGB(255, 241, 158, 210)
                    : Color.fromARGB(255, 247, 249, 242),
              ),
            ),
            Tab(
              icon: Icon(
                Icons.person,
                size: 30,
                color: _tabController.index == 2
                    ? Color.fromARGB(255, 241, 158, 210)
                    : Color.fromARGB(255, 247, 249, 242),
              ),
            ),
          ],
          indicatorColor: Color.fromARGB(255, 241, 158, 210),
        ),
      ),
    );
  }
}
