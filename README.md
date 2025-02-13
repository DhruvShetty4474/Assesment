**FilamentAI**
A new Flutter project that provides real-time MongoDB updates with notifications.
**Getting Started**
After cloning and running the application, you'll need to configure two permissions:

1. Disable Battery Optimization
2. Allow All Notifications

If you decline these initial prompts, you'll be redirected to the App Settings to enable them manually. The application will only run after these permissions are granted.
**Features**
This application connects to MongoDB (MongoDB Atlas for this project) using WebSocket technology. Any database operations are instantly reflected in the UI and trigger notifications:

1. Insert Operations: Trigger an alarm notification that continues until the user clicks the "Stop" button or accesses the phone's status bar/notification panel
2. Update/Delete Operations: Generate standard notifications

**Background Operation**
The application maintains full functionality even when:

Running in the background
Removed from the recent apps list
Detached from the main process

This ensures continuous server connection and notification delivery.


**Application Screenshots**


![Screenshot 2025-02-13 065653](https://github.com/user-attachments/assets/a73a0fb1-011b-41e9-83c0-4d472378534c)


**IMAGE FOR NORMAL NOTIFICATION**
![image](https://github.com/user-attachments/assets/50169aff-3c6d-4a8d-b313-5a58da561b17)


**IMAGE OF THE ALARM NOTIFICATION**
![image](https://github.com/user-attachments/assets/b7eb1719-de8b-49bf-af40-fdfa7736606e)

IF YOU WANT ALSO WANT THE CODE OF THE SERVER ITS IS ALOS IN MY REPO CALLED SERVER :)


