import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_clone_tutorial/constants.dart';
import 'package:tiktok_clone_tutorial/models/user.dart' as model;
import 'package:tiktok_clone_tutorial/views/widgets/screens/auth/login_screen.dart';
import 'package:tiktok_clone_tutorial/views/widgets/screens/home_screen.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  Rx<User>? _user;
  Rx<File> pickedImage = File("").obs;

  File? get profilePhoto => pickedImage.value;
  User get user => FirebaseAuth.instance.currentUser!;

  @override
  void onReady() {
    super.onReady();
    // _user = Rx<User?>(firebaseAuth.currentUser);
    // _user.bindStream(firebaseAuth.authStateChanges());
    // ever(_user, _setInitialScreen);

    //Used manual check instead of stream check so that the auth state works when we are complete with process
    _setInitialScreen();
  }

  _setInitialScreen() {
    if (FirebaseAuth.instance.currentUser == null) {
      Get.offAll(() => LoginScreen());
    } else {
      Get.offAll(() => const HomeScreen());
    }
  }

  void pickImage() async {
    final pickedImage2 =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage2 != null) {
      Get.snackbar('Profile Picture',
          'You have successfully selected your profile picture');
    }
    pickedImage = Rx<File>(File(pickedImage2!.path));
    update();
  }

  // upload to firebase storage
  Future<String> uploadToStorage(File image) async {
    TaskSnapshot snapshot = await firebaseStorage
        .ref()
        .child("images/${firebaseAuth.currentUser!.uid}.jpg")
        .putFile(image);
    String downloadUrl = "";
    if (snapshot.state == TaskState.success) {
      downloadUrl = await snapshot.ref.getDownloadURL();
    }
    return downloadUrl;
  }

  //registering the user
  void registerUser(String username, String email, String password, File? image) async {
    try {
      if(username.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          image!=null) {
        //save out user to our auth and firebase firestore
        UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password
            );
        String downloadUrl = "";
        try {
          downloadUrl = await uploadToStorage(image);
        } catch (e) {
          downloadUrl = "error";
          print(e);
        }
        model.User user = model.User(
          name: username,
          email: email,
          uid: cred.user!.uid,
          profilePhoto: downloadUrl,
        );
        cred.user!.uid.printInfo();

        // Updated This are and directly used the firebase firestore instance
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());
        _setInitialScreen();
      } else {
        Get.snackbar(
          'Error Creating Account',
          'Please enter all the fields',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error Creating Account',
        e.toString(),
      );
    }
  }

  void loginUser(String email, String password) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password);
        print('log success');
        _setInitialScreen();
      } else {
        Get.snackbar(
          'Error Logging in',
          'Please enter all the fields',
        );
      }
    } catch(e) {
      Get.snackbar(
        'Error Logging in',
        e.toString(),
      );
    }
  }

  void signOut() async {
    await firebaseAuth.signOut();
    _setInitialScreen();
  }
}
