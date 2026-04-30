# Adhira - Women Safety and Support App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Google_Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white)

**Adhira** is a comprehensive, multilingual women's safety and support platform designed to provide immediate assistance, foster community empowerment, and offer real-time legal and safety guidance. 

The application is built with a **Flutter** frontend for cross-platform compatibility (Web, Desktop, Mobile) and a robust **Node.js/Express** backend powered by **MongoDB** and cutting-edge AI integrations.

## 🚀 Key Features

- ** SOS & Real-time Distress Actions**: Instant access to emergency numbers (112, 1091) and actionable safety steps based on the severity of the user's situation.
- **Multilingual Support**: Accessible in English and 8 Indian regional languages (Hindi, Bengali, Telugu, Marathi, Tamil, Urdu, Gujarati, Kannada) to ensure language is not a barrier to safety.
- **AI Sentiment Analysis**: Automatically analyzes community posts to detect distress levels (Urgency: Red/Yellow/Green), toxicity, and automatically categorizes fields (e.g., Stalking, Domestic Violence).
- **Know Your Community**: A dynamic news and resources feed powered by Gemini AI, pulling the latest relevant safety articles, blogs, and support resources based on user search.
- **"Sophie" AI Assistant**: An empathetic, supportive AI chatbot (powered by Groq/Llama-3 and Gemini) that provides actionable safety steps and simple explanations of Indian laws (IPC/BNS).
- **Role-Based Architecture**: Distinct interfaces and functionalities for **Users** (seeking support) and **Volunteers** (offering assistance and guidance).
- **Community Stories**: A safe space for users to share their experiences (anonymously if preferred) to inspire, raise awareness, and build a stronger community.

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Node.js, Express.js
- **Database**: MongoDB (Mongoose)
- **AI Integrations**: 
  - **Google Gemini API** (Community content curation & advanced Sentiment Analysis)
  - **Groq API** (Llama-3 model for rapid, empathetic Chatbot responses)

## Run on Windows (PowerShell)

### Quick Start (print commands)
From the project root, you can run the provided script to set up and start the application:
```powershell
powershell -ExecutionPolicy Bypass -File .\run-windows.ps1 -Port 5000
```

### 1) Start MongoDB locally
Ensure MongoDB is running on your machine:
- Installed as Windows service: `net start MongoDB`
- Manual start: `mongod --dbpath C:\data\db`

### 2) Run Backend
```powershell
cd Backend
npm install
$env:PORT=5000
if (!(Test-Path .env)) { Copy-Item .env.example .env }
```

**Environment Variables Setup:**
Make sure to add your API keys to the `.env` file or export them in your terminal:
```powershell
$env:GROQ_API_KEY="your_groq_key"
$env:GEMINI_API_KEY="your_gemini_sentiment_key"
$env:GEMINI_API_KEY_COMMUNITY="your_gemini_community_key"
```

Start the backend server:
```powershell
npm run dev
```
*The Backend will listen on `http://127.0.0.1:5000`.*

### 3) (Optional) Seed Admin User
```powershell
cd Backend
npm run seed:admin
```
*Default login: `admin / admin` (from `Backend/.env` defaults in script).*

### 4) Run Flutter Frontend
Open a new terminal and navigate to the frontend directory:
```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
```
*Note: If the backend runs on another port, update `API_BASE_URL` to match.*

## Important Notes
- Signup requires selecting a role (`user` or `volunteer`).
- If a logged-in account has no role (e.g., first-time Google Auth), the app will prompt for a role selection before granting dashboard access.
- The Chatbot uses Groq when `GROQ_API_KEY` is present; otherwise, it falls back to Gemini or built-in safety replies.
- The AI Sentiment analyzer automatically filters toxic content and escalates urgent posts (Red status) requiring immediate attention.
