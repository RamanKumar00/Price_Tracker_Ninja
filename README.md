# Price Ninja 🥷
## Smart E-Commerce Price Tracker with Real-time Alerts

**Price Ninja** is a high-performance price tracking application that monitors products from **Amazon.in** and **Flipkart** 24/7. It provides real-time notifications via **WhatsApp** and **Email** the moment a price drops below your target.

![Aesthetics](https://img.shields.io/badge/Aesthetics-Premium_Midnight-blueviolet)
![Tech](https://img.shields.io/badge/Tech-Flutter_×_FastAPI-blue)
![Alerts](https://img.shields.io/badge/Alerts-WhatsApp_×_Email-success)

---

## 🔥 Key Features

- **24/7 Monitoring**: Automated background scraping using Selenium & BeautifulSoup.
- **Smart WhatsApp Alerts**: Integration with Twilio for instant mobile notifications.
- **Precision Email Alerts**: Detailed price drop summaries sent to your inbox.
- **Expiry Logic**: Set tracking timelines (e.g., "Track for 1 Month") to stay organized.
- **Relative Drop Insights**: See exactly how much the price has dropped since you started tracking (e.g., "₹500 off since tracking started").
- **Premium Midnight UI**: A stunning, animated interface with Neon Glassmorphism.
- **Guest Mode**: Start tracking products instantly without the friction of a mandatory login.

---

## 🛠️ Technology Stack

### Frontend (Mobile App)
- **Framework**: Flutter
- **State Management**: Riverpod
- **API Client**: Dio
- **Animations**: Flutter Animate
- **Storage**: SharedPreferences (Guest Session handling)

### Backend (Server)
- **Framework**: Python FastAPI
- **Scraper**: Selenium + BeautifulSoup4
- **Messaging**: Twilio (WhatsApp) & SMTPLIB (Email)
- **Data Validation**: Pydantic

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK
- Python 3.10+
- Chrome DevTools (for Selenium)

### 2. Backend Setup
```bash
cd price_ninja_backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```
*Note: Configure your `.env` file with Twilio and SMTP credentials.*

### 3. Frontend Setup
```bash
cd price_ninja
flutter pub get
flutter run
```

---

## 📸 Screenshots & Showcase
*Download the app and experience the premium Neon aesthetics.*

---

## 🤝 Contributing
Feel free to fork this project and submit PRs. Let's make price tracking smarter!

---
**Developed with ❤️ by [Raman Kumar](https://github.com/RamanKumar00)**
