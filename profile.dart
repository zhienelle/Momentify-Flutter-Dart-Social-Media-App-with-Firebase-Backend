import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfilePage(),
    theme: ThemeData(
      fontFamily: 'simpletext',
    ),
  ));
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String userId = '';
  String username = '';
  String profilePicture = '';
  String bio = '';
  String name = '';
  int followerCount = 0;
  int followingCount = 0;
  List<DocumentSnapshot> posts = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Function to load userId from SharedPreferences
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id =
        prefs.getString('user_id'); // Retrieve user_id from SharedPreferences
    if (id != null) {
      setState(() {
        userId = id;
      });
      _fetchUserDetails(userId); // Fetch user details from Firestore
      _fetchUserPosts(userId); // Fetch user's posts
    }
  }

  // Function to fetch user detail from Firestore
  Future<void> _fetchUserDetails(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('tbl_users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        username = userDoc['username'] ?? 'Unknown User';
        profilePicture = userDoc['profile_picture'] ?? '';
        bio = userDoc['bio'] ?? '';
        name = userDoc['name'] ?? '';
        followerCount = userDoc['followers_count'] ?? 0;
        followingCount = userDoc['following_count'] ?? 0;
      });
    }
  }

  // Function to fetch user details for a specific user_id
  Future<Map<String, String>> _fetchUserDetailsForPost(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('tbl_users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      return {
        'username': userDoc['username'] ?? 'Unknown User',
        'profile_picture': userDoc['profile_picture'] ?? '',
      };
    }
    return {'username': 'Unknown User', 'profile_picture': ''};
  }

  // Function to fetch posts for the user
  Future<void> _fetchUserPosts(String userId) async {
    QuerySnapshot postSnapshot = await FirebaseFirestore.instance
        .collection('tbl_posts')
        .where('user_id', isEqualTo: userId)
        .get();

    setState(() {
      posts = postSnapshot.docs; // Update the posts list with the fetched posts
    });
  }

  // Function to show the "See Users to Follow" dialog
  void _showUsersToFollowDialog() async {
    List<DocumentSnapshot> users = [];
    Map<String, bool> followStatus = {}; // Map to store follow status of each user

    // Fetch users from Firestore, excluding the current user
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('tbl_users')
        .get();

    setState(() {
      // Filter out the current user from the list of users to follow
      users = querySnapshot.docs.where((userDoc) => userDoc.id != userId).toList();
    });

    // Pre-fetch follow status for each user
    for (var userDoc in users) {
      String followUserId = userDoc.id;
      // Check if the current user is following this user
      bool isFollowing = await _checkIfFollowing(followUserId);
      followStatus[followUserId] = isFollowing;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'List of Users',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'header',
              color: Color.fromARGB(255, 241, 158, 210),
            ),
          ),
          contentPadding: EdgeInsets.all(10.0),
          content: SingleChildScrollView(
            child: Container(
              width: 300.0,
              child: Column(
                children: users.map((userDoc) {
                  String followUserId = userDoc.id;
                  String username = userDoc['username'];
                  String profilePic = userDoc['profile_picture'] ?? '';

                  bool isFollowing = followStatus[followUserId] ?? false; // Fetch the pre-fetched status

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePic.isNotEmpty
                          ? NetworkImage(profilePic)
                          : AssetImage('images/default_profile.png') as ImageProvider,
                    ),
                    title: Text(
                      username,
                      style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 47, 47, 47), overflow: TextOverflow.ellipsis,),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Color.fromRGBO(232, 197, 229, 1)
                            : Color.fromARGB(255, 145, 221, 207),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                        textStyle: TextStyle(fontSize: 14),
                      ),
                      onPressed: () {
                        if (isFollowing) {
                          _unfollowUser(followUserId); // Unfollow the user
                        } else {
                          _followUser(followUserId); // Follow the user
                        }
                      },
                      child: Text(
                        isFollowing ? 'Unfollow' : 'Follow',
                        style: TextStyle(
                          color: Color.fromARGB(255, 47, 47, 47),
                          fontSize: 14, // Font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
  },
    );
  }

// Function to check if the current user is following another user
  Future<bool> _checkIfFollowing(String followUserId) async {
    DocumentSnapshot followDoc = await FirebaseFirestore.instance
        .collection('tbl_users')
        .doc(userId)
        .collection('following')
        .doc(followUserId)
        .get();

    return followDoc.exists; // Returns true if the document exists (meaning the user is following)
  }

// Function to follow a user
  Future<void> _followUser(String followUserId) async {
    try {
      // Get the username of the user being followed
      DocumentSnapshot followedUserSnapshot = await FirebaseFirestore.instance.collection('tbl_users').doc(followUserId).get();
      String followedUsername = followedUserSnapshot['username'];

      // Update the following count of the signed-in user
      DocumentReference userRef = FirebaseFirestore.instance.collection('tbl_users').doc(userId);
      await userRef.update({
        'following_count': FieldValue.increment(1),
      });

      // Update the followers count of the followed user
      DocumentReference followedUserRef = FirebaseFirestore.instance.collection('tbl_users').doc(followUserId);
      await followedUserRef.update({
        'followers_count': FieldValue.increment(1),
      });

      // Add the follow relationship to the "following" collection
      await userRef.collection('following').doc(followUserId).set({
        'username': followedUsername,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Optionally, add the user to the "followers" collection of the followed user
      await followedUserRef.collection('followers').doc(userId).set({
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Dismiss the dialog
      Navigator.pop(context);

      // Update the local following count
      setState(() {
        followingCount += 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error following user')));
    }
  }

// Function to unfollow a user
  Future<void> _unfollowUser(String followUserId) async {
    try {
      // Update the following count of the signed-in user
      DocumentReference userRef = FirebaseFirestore.instance.collection('tbl_users').doc(userId);
      await userRef.update({
        'following_count': FieldValue.increment(-1),
      });

      // Update the followers count of the followed user
      DocumentReference followedUserRef = FirebaseFirestore.instance.collection('tbl_users').doc(followUserId);
      await followedUserRef.update({
        'followers_count': FieldValue.increment(-1),
      });

      // Remove the follow relationship from the "following" collection
      await userRef.collection('following').doc(followUserId).delete();

      // Optionally, remove the user from the "followers" collection of the followed user
      await followedUserRef.collection('followers').doc(userId).delete();

      // Dismiss the dialog
      Navigator.pop(context);

      // Update the local following count
      setState(() {
        followingCount -= 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error unfollowing user')));
    }
  }


  void _deletePost(String postId, int index) async {
    try {
      // Delete comments associated with the post from tbl_comments
      await FirebaseFirestore.instance
          .collection('tbl_comments')
          .where('post_id', isEqualTo: postId)
          .get()
          .then((snapshot) async {
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      // Delete from Firebase Firestore
      await FirebaseFirestore.instance.collection('tbl_posts').doc(postId).delete();

      // Remove the post from the local list
      setState(() {
        posts.removeAt(index);
      });

      // Optionally, show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully')));
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post')));
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(241, 158, 210, 1),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(247, 249, 242, 1),
                Color.fromRGBO(241, 158, 210, 1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // User profile section
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.fromARGB(255, 241, 158, 210),
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePicture.isNotEmpty
                            ? NetworkImage(profilePicture)
                            : AssetImage('images/comment_profile.jpg') as ImageProvider,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'header',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2F2F),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'simpletext',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2F2F),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'simpletext',
                        color: Color(0xFF2F2F2F),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(232, 197, 229, 1),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _showUsersToFollowDialog,  // This triggers the dialog
                      child: Text(
                        'See All Users',
                        style: TextStyle(
                          color: Color(0xFF2F2F2F),
                          fontFamily: 'normal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$followerCount',
                              style: TextStyle(
                                fontSize: 25,
                                fontFamily: 'header',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F2F2F),
                              ),
                            ),
                            Text(
                              'Followers',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'normal',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F2F2F),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 80),
                        Column(
                          children: [
                            Text(
                              '$followingCount',
                              style: TextStyle(
                                fontSize: 25,
                                fontFamily: 'header',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F2F2F),
                              ),
                            ),
                            Text(
                              'Following',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'normal',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F2F2F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Display the posts using ListView.builder
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
                    String postId = post.id;
                    String imageUrl = post['media_url'] ?? '';
                    String caption = post['content'] ?? '';
                    Timestamp timestamp = post['timestamp'];
                    int likesCount = post['likes_count'] ?? 0;
                    int commentsCount = post['comments_count'] ?? 0;
                    String userId = post['user_id']; // Get the user_id for this post

                    // Convert timestamp to readable format
                    String formattedTimestamp = timestamp != null
                        ? DateFormat('yyyy-MM-dd | HH:mm').format(timestamp.toDate().toLocal())
                        : 'No timestamp';

                    return FutureBuilder<Map<String, String>>(
                      future: _fetchUserDetailsForPost(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}'); // Handle errors
                        }

                        // Extract user details
                        var userData = snapshot.data!;
                        String postUsername = userData['username'] ?? 'Unknown User';
                        String postProfilePic = userData['profile_picture'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Card(
                            elevation: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User info and timestamp
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: postProfilePic.isNotEmpty
                                                ? NetworkImage(postProfilePic)
                                                : AssetImage('images/default_profile.png')
                                            as ImageProvider,
                                          ),
                                          SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                postUsername,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'simpletext', fontSize: 16, color: Color.fromARGB(255, 47, 47, 47)),
                                              ),
                                              Text(formattedTimestamp,
                                                style: TextStyle(fontSize: 12, fontFamily: 'simpletext', color: Color.fromARGB(255, 47, 47, 47)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Delete button
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Color.fromARGB(255, 241, 158, 210)),
                                        onPressed: () {
                                          _deletePost(postId, index);
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Caption
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                                  child: Text(
                                    caption,
                                    style: TextStyle(fontSize: 16, fontFamily: 'simpletext', color: Color.fromRGBO(47, 47, 47, 1)),
                                  ),
                                ),

                                // Image section
                                if (imageUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                                    child: Image.network(imageUrl),
                                  ),

                                // Likes and comments count
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: Color.fromARGB(255, 241, 158, 210), // Pink color
                                            size: 20, // Adjust the size as needed
                                          ),
                                          SizedBox(width: 5),
                                          Text('$likesCount Likes', style: TextStyle(fontSize: 14, fontFamily: 'simpletext', color: Color.fromRGBO(47, 47, 47, 1)),),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.comment,
                                            color: Color.fromARGB(255, 241, 158, 210),
                                            size: 20,
                                          ),
                                          SizedBox(width: 5),
                                          Text('$commentsCount Comments', style: TextStyle(fontSize: 14, fontFamily: 'simpletext', color: Color.fromRGBO(47, 47, 47, 1)),),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
