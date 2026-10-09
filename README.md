# Firebase Task Manager

Flutter app for the Module 16 assignment: Firebase Authentication, Cloud Firestore CRUD, FCM push notifications and local notifications.

## Features
- Email/password sign up and sign in, Google sign-in, password reset
- Task CRUD in Cloud Firestore (title, description, due date, priority, completed status, created date)
- Search, Pending/Completed filters, sort, delete confirmation dialog
- FCM push notifications with device token handling
- Local notification when a push arrives while the app is in the foreground
- Background and terminated state handling
- Notification tap opens the Task List, or the exact task when a taskId is sent
- Different notification channel per task priority

## Tech
Flutter, firebase_core, firebase_auth, cloud_firestore, firebase_messaging, flutter_local_notifications, google_sign_in

## Run
1. `flutter pub get`
2. `flutterfire configure` (use your own Firebase project)
3. Add your SHA-1 and SHA-256 to the Firebase Android app (needed for Google sign-in)
4. `flutter run`

## Test push notifications
1. Run the app and copy the `FCM TOKEN` from the debug console.
2. Firebase Console -> Messaging -> New campaign -> Send test message.
3. To open a specific task, send a campaign with custom data `taskId=<document id>` and `priority=High`.