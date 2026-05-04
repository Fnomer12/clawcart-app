# CLAWCART 🦞  
### AI-Powered Agentic Commerce Mobile Application  

## Student Information  
**Name:** Adjei Sampson Kofi  
**Student ID:** 224CS02001270  
**Course:** Mobile Application Development (Flutter)  

---

## 📱 Application Name  
**ClawCart – AI Shopping Assistant**

---

## 🚀 Project Overview  

ClawCart is an **AI-powered agentic commerce mobile application** designed to help users intelligently search, compare, and discover products across multiple online marketplaces.

Unlike traditional e-commerce platforms, ClawCart acts as a **smart agent**, understanding user intent and automatically fetching the best product options, prices, and recommendations in real-time.

---

## 🧠 Key Features  

- 🔍 **Smart AI Search**  
  Users can search naturally (e.g., *“iPhone 13 in Ghana”*), and the system interprets intent.

- 🌍 **Multi-Country Support**  
  Supports Ghana, UK, and US with localized pricing and marketplaces.

- 💱 **Automatic Currency Conversion**  
  Converts prices into the user’s selected country currency.

- 🧠 **Agentic Commerce Engine**  
  The backend acts as an intelligent agent:
  - Fetches real-time data from multiple sources  
  - Filters irrelevant results  
  - Ranks best products  

- 📊 **Price Filtering System**  
  Users can set a custom budget range using a slider.

- ❤️ **Save Products (Favorites)**  
  Users can save items for later viewing.

- 🧾 **AI Suggestions**  
  System suggests better search queries dynamically.

- 🔗 **Direct Purchase Links**  
  Users can open product links directly in browser.

- 🔐 **Authentication System**  
  Firebase Authentication (Email/Password + Google Sign-In)

---

## 🏗️ System Architecture  

### Frontend  
- Flutter (Dart)  
- Provider (State Management)  
- Firebase Auth + Firestore  

### Backend  
- Node.js (Express)  
- SerpAPI (Product search engine)  
- Currency API (Exchange rates)  

### Integration Flow  
1. User enters search query  
2. App sends request to backend  
3. Backend fetches products from:
   - Google Shopping  
   - Online marketplaces (Jumia, Jiji, etc.)  
4. AI logic filters & ranks results  
5. Prices converted to local currency  
6. Results returned to app  

---

## 📂 Project Structure  
lib/
├── screens/
├── providers/
├── services/
├── models/
├── widgets/
├── app/

Backend:
clawcart-backend/
├── server.js
├── .env

---

## ⚙️ Requirements  

### Software  
- Flutter SDK  
- Node.js  
- Android Studio / Xcode  
- Firebase Project  

---

## ▶️ How to Run the Project  

### 1. Clone Project  
git clone 
cd clawcart

### 2. Install Flutter Dependencies  
flutter pub get

### 3. Setup Backend  
cd clawcart-backend
npm install

Create `.env` file:

SERPAPI_KEY=your_api_key_here

Run backend:
node server.js

---

### 4. Expose Backend (Important for Mobile Testing)  
ngrok http 3000

Copy the HTTPS link and update your Flutter app:

const baseUrl = “https://your-ngrok-link.ngrok-free.dev”;

---

### 5. Run App  
flutter run

---

## ⚠️ Notes  

- Ensure internet connection is stable  
- Firebase must be properly configured  
- Ngrok must be running when testing on real device  
- Some products may not display price if source lacks data  

---

## 📌 Special Instructions  

- Use **physical device (recommended)** for best performance  
- Login is required before using search features  
- Saved products are stored in Firebase Firestore  

---

## 🎯 Conclusion  

ClawCart demonstrates how **AI + real-time data + mobile development** can be combined to build a powerful **agentic commerce system** that simplifies online shopping and improves decision-making.

---

🔥 *This project represents a modern approach to intelligent e-commerce systems.*  