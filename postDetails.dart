import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class PostDetails extends StatefulWidget {
  final String postId;
  final String username;
  final String caption;
  final String imageUrl;
  final String profilePic;
  final String formattedDate;
  final String formattedTime;
  final String userId;

  // Constructor accepting necessary post details
  PostDetails({
    required this.postId,
    required this.username,
    required this.caption,
    required this.imageUrl,
    required this.profilePic,
    required this.formattedDate,
    required this.formattedTime,
    required this.userId,
  });

  @override
  _PostDetailsState createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  int likeCount = 0;
  bool isLiked = false;
  bool showComments = false;
  List<Map<String, String>> comments = [];
  final TextEditingController commentController = TextEditingController();

  // Function to update like count in Firestore
  Future<void> updateLikeCountInFirebase() async {
    try {
      DocumentReference postRef = FirebaseFirestore.instance.collection('tbl_posts').doc(widget.postId);
      await postRef.update({
        'likes_count': likeCount,
      });
    } catch (e) {
      print('Failed to update like count: $e');
    }
  }

  // Function to add comment and update comment count
  Future<void> addCommentToFirebase(String text) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      if (userId == null) {
        print('User ID is null.');
        return;
      }

      DateTime now = DateTime.now();
      final commentData = {
        'post_id': widget.postId,
        'user_id': userId, // Only save the user_id
        'content': text,
        'timestamp': now, // Save as DateTime
      };

      // Add the comment to Firestore
      var commentRef = await FirebaseFirestore.instance.collection('tbl_comments').add(commentData);

      String commentId = commentRef.id;
      await commentRef.update({'comment_id': commentId});

      // Update the comments count in the post
      DocumentReference postRef = FirebaseFirestore.instance.collection('tbl_posts').doc(widget.postId);
      await postRef.update({
        'comments_count': FieldValue.increment(1),
      });

      commentController.clear();
    } catch (e) {
      print('Failed to add comment: $e');
    }
  }

  // Function to check if the user has liked this post before
  Future<void> checkIfUserLikedPost() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId != null) {
      bool hasLiked = prefs.getBool('liked_${widget.postId}_$userId') ?? false;
      setState(() {
        isLiked = hasLiked;
      });
    }
  }

  // Function to update like status in SharedPreferences
  Future<void> updateLikeStatusInPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId != null) {
      prefs.setBool('liked_${widget.postId}_$userId', isLiked);
    }
  }

  @override
  void initState() {
    super.initState();
    checkIfUserLikedPost(); // Check if the user has liked the post when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(247, 249, 242, 1),
      body: Column(
        children: [
          // Back arrow button to go back to the feed page
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: 30),
                onPressed: () {
                  Navigator.pop(context);  // Navigate back to the previous screen
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('tbl_posts').doc(widget.postId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return Center(child: Text('Post not found.'));
                }

                var postData = snapshot.data!;
                likeCount = postData['likes_count'] ?? 0;
                int commentCount = postData['comments_count'] ?? 0;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post details UI
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Color.fromRGBO(241, 158, 210, 1), width: 3),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(radius: 33, backgroundImage: NetworkImage(widget.profilePic)),
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.username, style: TextStyle(fontFamily: 'normal', fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromRGBO(47, 47, 47, 1))),
                                Text('${widget.formattedDate} | ${widget.formattedTime}', style: TextStyle(fontFamily: 'simpletext', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(widget.caption, style: TextStyle(fontSize: 16, fontFamily: 'simpletext', color: Color.fromRGBO(47, 47, 47, 1))),
                        SizedBox(height: 10),
                        if (widget.imageUrl.isNotEmpty)
                          Image.network(widget.imageUrl, width: double.maxFinite, fit: BoxFit.cover),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 30),
                                  color: isLiked ? Color.fromRGBO(232, 197, 229, 1) : Colors.grey,
                                  onPressed: () {
                                    setState(() {
                                      if (isLiked) {
                                        likeCount--;
                                      } else {
                                        likeCount++;
                                      }
                                      isLiked = !isLiked;
                                    });
                                    updateLikeCountInFirebase(); // Update like count in Firebase
                                    updateLikeStatusInPreferences(); // Save like status in SharedPreferences
                                  },
                                ),
                                SizedBox(width: 3),
                                Text('$likeCount Likes', style: TextStyle(fontFamily: 'simpletext', color: Color.fromRGBO(47, 47, 47, 1), fontSize: 16)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.comment, size: 30),
                                  color: Color.fromRGBO(232, 197, 229, 1),
                                  onPressed: () {
                                    setState(() {
                                      showComments = !showComments;
                                    });
                                  },
                                ),
                                SizedBox(width: 3),
                                Text('$commentCount Comments', style: TextStyle(fontFamily: 'simpletext', color: Color.fromRGBO(47, 47, 47, 1), fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                        if (showComments)
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('tbl_comments')
                                .where('post_id', isEqualTo: widget.postId)
                                .get(),
                            builder: (context, commentSnapshot) {
                              if (commentSnapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (!commentSnapshot.hasData || commentSnapshot.data!.docs.isEmpty) {
                                return Text('No comments yet.');
                              }

                              var comments = commentSnapshot.data!.docs;
                              return Column(
                                children: List.generate(comments.length, (index) {
                                  var comment = comments[index];
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance.collection('tbl_users').doc(comment['user_id']).get(),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                        return Text('User not found.');
                                      }

                                      var userData = userSnapshot.data!;
                                      String username = userData['username'] ?? 'Unknown User';
                                      String profile_picture = userData['profile_picture'] ?? '';

                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(radius: 20, backgroundImage: NetworkImage(profile_picture)),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                  SizedBox(height: 5),
                                                  Text(comment['content'], style: TextStyle(fontSize: 14)),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    DateFormat('yyyy-MM-dd | HH:mm').format(comment['timestamp'].toDate()),
                                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Color.fromARGB(255, 47, 47, 47), width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Color.fromARGB(255, 241, 158, 210), width: 2)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(fontFamily: 'simpletext', fontSize: 16, fontWeight: FontWeight.normal, color: Color.fromRGBO(47, 47, 47, 1)),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Color.fromRGBO(241, 158, 210, 1),
                  onPressed: () {
                    if (commentController.text.isNotEmpty) {
                      addCommentToFirebase(commentController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
