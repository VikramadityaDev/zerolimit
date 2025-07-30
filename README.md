# zerolimit

Zerolimit is a cloud storage app that lets users securely upload and access their photos and videos via Telegram. It offers a clean, user-friendly interface for managing media without relying on traditional third-party cloud services.


<p align="left">
<a href="https://github.com/VikramadityaDev/zerolimit/releases/download/download/app-armeabi-v7a-release.apk"><img src="https://img.shields.io/github/downloads/VikramadityaDev/zerolimit/total?color=g&label=Downloads&logo=android&logoColor=white&style=for-the-badge"></a>
</p>

## 🎯 Project Goals
- ✅ Offering **unlimited free storage** without depending on traditional cloud services like Google Drive or Dropbox.
- ✅ Build a lightweight backend that interacts with the Telegram API to authenticate users and upload media.
- ✅ Develop a mobile app using **Flutter** to provide a beautiful and intuitive interface.
- ✅ Leverage Telegram's "Saved Messages" as a **zero-cost storage** backend.
- ✅ Deploy the backend using cloud hosting service.

## 🚀 Features
- 📱 **Phone Number Login via Telegram**
- 🔐 **Session-based Authentication**
- 📨 **Send OTP and Handle 2FA**
- 📤 **Send Image/Video to Saved Messages**
- 💬 **Simple Message Upload Test Route**
- 📂 **View Uploaded Media**
- 📤 **Download Media with Previews**
- 🗂️ **Tag & Categorize Files**

## 📁 Tiered Upload Limits

| Tier     | Max Upload Size | Cost               |
|----------|------------------|--------------------|
| Free     | 2GB per file    | Free               |
| Premium  | 4GB per file    | Subscription-based |

To enable 4GB uploads, users must activate a Telegram Premium subscription.

## 📸 Screenshots

| Login Screen | OTP Screen | 2FA Screen |
|--------------|------------|------------|
| <img src="screenshots/1 ss.png" width="250"/> | <img src="screenshots/2 ss.png" width="250"/> | <img src="screenshots/3 ss.png" width="250"/> |

| Home Screen | Download Screen | Upload Screen |
|-------------|-----------------|---------------|
| <img src="screenshots/4 ss.png" width="250"/> | <img src="screenshots/5 ss.png" width="250"/> | <img src="screenshots/6 ss.png" width="250"/> |



## 🛠️ Planned Features (in development)
 
- **Auto‑upload from user's gallery to Telegram**  
- **Possible integration: multi-file uploads**

## 🔧 Tech Stack
| Layer         | Stack / Tools            |
|---------------|--------------------------|
| **Frontend**  | Flutter                  |
| **Backend**   | Python + Quart (async Flask) |
| **API Comm.** | RESTful APIs             |
| **Messaging** | Pyrogram (MTProto API)   |
| **Hosting**   | Railway (for backend)    |
| **Storage**   | Telegram (Saved Messages) |


## 🤝 Contributing
**Contributions are welcome! Whether it's improving the user interface or adding new features, feel free to fork this project, open issues, or submit pull requests.**

## ✨ Author
Made with ❤️ by VikramadityaDev
