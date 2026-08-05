import 'package:final_project_baylon_francisco/homenavigator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CreatePostPage(),
  ));
}

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _mediaUrlController =
      TextEditingController(); // Controller for media URL
  String? _mediaPreviewUrl;

  // Define the getUserData method
  Future<Map<String, String>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    // Check if the userId and username are correctly retrieved
    if (userId == null) {
      print("User data not found in SharedPreferences");
    } else {
      print("User ID: $userId");
    }

    return {
      'user_id': userId ?? ''};
  }

  // Method to submit the post
  Future<void> _submitPost() async {
    // Retrieve user data from SharedPreferences
    Map<String, String> userData = await getUserData();
    String userId = userData['user_id'] ?? '';
    String username = userData['username'] ?? '';

    if (_postController.text.isNotEmpty ||
        _mediaUrlController.text.isNotEmpty) {
      try {
        String? mediaUrl = _mediaUrlController.text.isNotEmpty
            ? _mediaUrlController.text
            : null;

        // Add post to Firestore
        DocumentReference postRef =
            await FirebaseFirestore.instance.collection('tbl_posts').add({
          'user_id': userId,
          'content': _postController.text,
          'media_url': mediaUrl,
          'media_type': mediaUrl != null && mediaUrl.endsWith('.mp4')
              ? 'video'
              : 'image', // Check if the URL is a video or image
          'timestamp': FieldValue.serverTimestamp(),
          'likes_count': 0,
          'comments_count': 0,
        });

        // Adding post_id field (same as the document ID)
        await postRef.update({
          'post_id': postRef.id, // Use the Firebase-generated ID as the post_id
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post submitted successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeNavigator()), // Redirect to feed through home navigator
        ); // Navigate back to the feed page
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit post: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add text or a valid media URL!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 247, 249, 242),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create a Post",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 30,
                      color: Color.fromARGB(255, 241, 158, 210),
                      fontFamily: "header",
                      fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 30),

                // Media URL Section
                Text(
                  'Media',
                  style: TextStyle(
                    fontFamily: 'header',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(47, 47, 47, 1),
                  ),
                ),
                SizedBox(height: 20),

                // Input for Media URL (Image)
                TextField(
                  controller: _mediaUrlController,
                  decoration: InputDecoration(
                    hintText: 'Enter media URL here...',
                    hintStyle: TextStyle(
                      fontFamily: 'simpletext',
                      color: Color.fromRGBO(47, 47, 47, 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromRGBO(47, 47, 47, 1), width: 2),
                    ),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                      BorderSide(color: Color.fromRGBO(145, 221, 207, 1), width: 2),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  style: TextStyle(
                    fontFamily: 'simpletext',
                    fontSize: 18,
                    color: Color.fromRGBO(47, 47, 47, 1),
                  ),
                  onChanged: (url) {
                    setState(() {
                      // Check if URL is a valid media
                      _mediaPreviewUrl = url.isNotEmpty ? url : null;
                    });
                  },
                ),
                SizedBox(height: 10),

                // Display media preview (Image)
                if (_mediaPreviewUrl != null && _mediaPreviewUrl!.isNotEmpty)
                  Center (
                    child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Image.network(
                            _mediaPreviewUrl!,  // Load the image
                            height: 200,
                            width: constraints.maxWidth,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    ),
                  ),

                // Caption Section
                SizedBox(height: 30),
                Text(
                  'Caption',
                  style: TextStyle(
                    fontFamily: 'header',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(47, 47, 47, 1),
                  ),
                ),
                SizedBox(height: 20),

                // Post Text Input
                TextField(
                  controller: _postController,
                  decoration: InputDecoration(
                    hintText: 'Enter your post text here...',
                    hintStyle: TextStyle(
                      fontFamily: 'simpletext',
                      color: Color.fromRGBO(47, 47, 47, 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromRGBO(47, 47, 47, 1), width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromRGBO(145, 221, 207, 1), width: 2),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  maxLines: 5,
                  style: TextStyle(
                    fontFamily: 'simpletext',
                    fontSize: 18,
                    color: Color.fromRGBO(47, 47, 47, 1),
                  ),
                ),
                SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 241, 158, 210),
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(
                      'Submit Post',
                      style: TextStyle(
                          color: Color.fromARGB(255, 47, 47, 47),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: "normal"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
