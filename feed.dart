import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'postDetails.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Feed(),
  ));
}

class Feed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _Feed(),
      theme: ThemeData(
        fontFamily: 'simpletext',
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  // Function to fetch user details
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('tbl_users').get();

    return usersSnapshot.docs.map((doc) {
      return {
        'username': doc['username'] ?? 'Unknown User',
        'profile_picture': doc['profile_picture'] ?? '',
      };
    }).toList();
  }

  // Function to fetch user detail
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('tbl_users')
        .doc(userId)
        .get();

    // Returning user details
    return userDoc.exists
        ? {
            'username': userDoc['username'] ?? 'Unknown User',
            'profile_picture': userDoc['profile_picture'] ?? ''
          }
        : {'username': 'Unknown User', 'profile_picture': ''};
  }

  Widget userAvatar(String imagePath, String username, double radius) {
    return Container(
      width: 80,
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Color.fromARGB(255, 241, 158, 210), width: 3),
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundImage: imagePath.isNotEmpty
                  ? NetworkImage(imagePath)
                  : AssetImage('images/comment_profile.jpg'),
            ),
          ),
          SizedBox(height: 5),
          Text(
            username,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Function to handle the like/unlike action
  Future<void> toggleLike(String postId, String userId, int likesCount) async {
    final postRef = FirebaseFirestore.instance.collection('tbl_posts').doc(postId);
    DocumentSnapshot postDoc = await postRef.get();
    List likedBy = List.from(postDoc['liked_by'] ?? []);
    bool hasLiked = likedBy.contains(userId);

    if (hasLiked) {
      likedBy.remove(userId);
      await postRef.update({
        'liked_by': likedBy,
        'likes_count': likesCount - 1,
      });
    } else {
      likedBy.add(userId);
      await postRef.update({
        'liked_by': likedBy,
        'likes_count': likesCount + 1,
      });
    }
  }

  // Function to check if the current user has liked the post
  Future<bool> checkIfLiked(String postId, String userId) async {
    DocumentSnapshot postDoc = await FirebaseFirestore.instance.collection('tbl_posts').doc(postId).get();
    List likedBy = List.from(postDoc['liked_by'] ?? []);
    return likedBy.contains(userId);
  }

  Widget buildPostCard(
    String username,
    String profilePicture,
    String formattedDate,
    String formattedTime,
    String content,
    String mediaType,
    String mediaUrl,
    int likesCount,
    int commentsCount,
    String postId,
    String userId,
    BuildContext context,
  ) {

    return GestureDetector(
      onTap: () {
        // Navigate to the PostDetails page when the post is clicked
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetails(
                postId: postId,
                username: username,
                caption: content,
                imageUrl: mediaUrl,
                profilePic: profilePicture,
                formattedDate: formattedDate,
                formattedTime: formattedTime,
                userId: userId,
              ),
            ));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : AssetImage('images/comment_profile.jpg'),
                      radius: 25,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      username,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formattedDate, style: TextStyle(fontSize: 12)),
                    Text(formattedTime, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15.0),
            // If the post contains media only (no content)
            if (mediaType.isNotEmpty && mediaUrl.isNotEmpty && content.isEmpty)
              Image.network(mediaUrl),
            // If the post contains text only (no media)
            if (content.isNotEmpty && mediaUrl.isEmpty)
              Text(content, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            // If the post contains both media and content
            if (content.isNotEmpty && mediaUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(content, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 15.0),
                  Image.network(mediaUrl),
                ],
              ),
            FutureBuilder<bool>(
              future: checkIfLiked(postId, userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                bool isLiked = snapshot.data ?? false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 30,
                            color: isLiked
                                ? Color.fromARGB(255, 241, 158, 210)
                                : Color.fromARGB(255, 241, 158, 210),
                          ),
                          onPressed: () {
                            toggleLike(postId, userId, likesCount);
                          },
                        ),
                        Text(
                          '$likesCount likes',
                          style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 47, 47, 47)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.comment,
                            size: 25,
                            color: Color.fromARGB(255, 241, 158, 210),
                          ),
                          onPressed: () {},
                        ),
                        Text(
                          '$commentsCount comments',
                          style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 47, 47, 47)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchUsers(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasError) {
              return Center(child: Text('Error loading users!'));
            }

            var users = userSnapshot.data ?? [];
            return StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('tbl_posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator()); // Loading indicator while waiting for data.
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Something went wrong!')); // Handle error
                }

                // Get the list of documents (posts) from the snapshot
                var posts = snapshot.data?.docs ?? [];

                return Container(
                  child: ListView(
                    children: [
                      // User avatars section
                      Container(
                        height: 100,
                        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: users
                              .map((user) => userAvatar(
                              user['profile_picture'], user['username'], 32))
                              .toList(),
                        ),
                      ),
                      // Post list section
                      SizedBox(
                        height: MediaQuery.of(context).size.height -
                            150, // Adjust height dynamically
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            var post = posts[index];

                            // Fetch post details
                            var content = post['content'] ?? '';
                            var mediaType = post['media_type'] ?? '';
                            var mediaUrl = post['media_url'] ?? '';
                            var likesCount = post['likes_count'] ?? 0;
                            var commentsCount = post['comments_count'] ?? 0;
                            var userId = post['user_id'] ?? '';
                            var timestamp = post['timestamp'] ?? Timestamp.now();

                            var date = (timestamp as Timestamp).toDate();

                            // Format the date and time
                            String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                            String formattedTime = DateFormat('HH:mm').format(date);

                            return FutureBuilder<Map<String, dynamic>>(
                              future:
                              getUserDetails(userId), // Fetch user details
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }

                                if (userSnapshot.hasError) {
                                  return Center(
                                      child: Text('Error fetching user data!'));
                                }

                                var username = userSnapshot.data?['username'] ??
                                    'Unknown User';
                                var profilePicture =
                                    userSnapshot.data?['profile_picture'] ?? '';

                                return buildPostCard(
                                  username,
                                  profilePicture,
                                  formattedDate,
                                  formattedTime,
                                  content,
                                  mediaType,
                                  mediaUrl,
                                  likesCount,
                                  commentsCount,
                                  post.id,
                                  userId,
                                  context,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                );
              },
            );
          }),
    );
  }
}
