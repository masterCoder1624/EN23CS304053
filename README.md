<<<<<<< HEAD
# InsightHub - AI-Powered Feedback Analytics Platform

<div align="center">

![InsightHub](https://img.shields.io/badge/status-active-brightgreen)
![Python](https://img.shields.io/badge/Backend-FastAPI-009688)
![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B)
![MongoDB](https://img.shields.io/badge/Database-MongoDB-13AA52)

**Intelligent customer feedback analysis with NLP, sentiment analysis, and AI insights.**

[Quick Start](#quick-start) • [Architecture](#architecture) • [Setup Guide](#setup-guide) • [API Documentation](#api-documentation)

</div>

---

## 🎯 Overview

InsightHub is a full-stack SaaS platform for analyzing customer feedback with AI-powered insights. Upload CSV files containing customer reviews and get:

- **Sentiment Analysis** - Positive/negative/neutral classification
- **Topic Extraction** - Identify frequently mentioned topics
- **Issue Detection** - Automatically surface product issues  
- **AI Insights** - Generated narratives about what customers love and complain about
- **Visual Analytics** - Dashboards with charts and metrics
- **Cross-Platform** - Works on Android, iOS, Web, and Desktop

---

## 🚀 Quick Start

### Backend (30 seconds)

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Start MongoDB (ensure it's running)
# macOS: brew services start mongodb-community
# Windows: net start MongoDB (if installed as service)

# 3. Start API server
uvicorn backend.main:app --reload

# Server runs at: http://localhost:8000
```

### Frontend (30 seconds)

```bash
# 1. Install Flutter dependencies  
cd insighthub_app
flutter pub get

# 2. Run on emulator/simulator
flutter run

# 3. Test - Upload sample_reviews.csv via Upload tab
```

### Test Connectivity

```bash
# Backend health check
curl http://localhost:8000/health

# Expected: {"success": true, "data": {"status": "healthy", ...}}
```

---

## 📋 Architecture

```
insighthub/
├── app/                          # FastAPI Backend
│   ├── main.py                   # Application entry point
│   ├── core/
│   │   └── config.py             # Environment configuration
│   ├── db/
│   │   └── mongodb.py            # Database connection
│   ├── models/
│   │   ├── response_model.py     # API response schema
│   │   ├── review_model.py       # Review data model
│   │   └── ...
│   ├── routes/
│   │   ├── upload.py             # CSV upload endpoint
│   │   └── analysis.py           # Analytics endpoint
│   ├── services/                 # Business logic
│   │   ├── csv_parser.py         # CSV reading
│   │   ├── sentiment_service.py  # Sentiment analysis  
│   │   ├── topic_service.py      # Topic extraction
│   │   └── insight_service.py    # AI insight generation
│   └── repositories/
│       └── reviews_repository.py # Database access layer
│
├── insighthub_app/               # Flutter Frontend
│   ├── lib/
│   │   ├── main.dart             # App entry point
│   │   ├── config/
│   │   │   └── api_config.dart   # Backend URL configuration
│   │   ├── services/
│   │   │   └── api_service.dart  # API client with retry logic
│   │   ├── screens/              # UI screens
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── upload_screen.dart
│   │   │   ├── insights_screen.dart
│   │   │   └── explorer_screen.dart
│   │   └── widgets/              # Reusable UI components
│   ├── pubspec.yaml              # Flutter dependencies
│   └── ...
│
├── sample_reviews.csv            # Sample data for testing
├── requirements.txt              # Python dependencies
├── .env                          # Configuration (local)
├── .env.example                  # Configuration template
├── SETUP_AND_DEPLOYMENT.md       # Detailed setup guide
└── README.md                     # This file
```

---

## 🔧 Technology Stack

### Backend
- **Framework**: FastAPI (Python)
- **Database**: MongoDB
- **Cache**: In-memory (can scale to Redis)
- **NLP**: TextBlob (sentiment), scikit-learn (TF-IDF)
- **Server**: Uvicorn + ASGI

### Frontend
- **Framework**: Flutter (Dart)
- **UI Kit**: Material Design 3
- **HTTP**: http package with retry logic
- **Charts**: fl_chart
- **File Picker**: file_picker package

### Infrastructure
- **Containerization**: Docker (optional)
- **Reverse Proxy**: Nginx (production)
- **SSL**: Let's Encrypt (production)
- **Platform**: AWS, DigitalOcean, or on-premise

---

## 📖 Setup Guide

For detailed setup instructions including:
- MongoDB configuration (local vs. Atlas)
- Environment variables
- Troubleshooting connection issues
- Production deployment
- Docker setup

→ **See [SETUP_AND_DEPLOYMENT.md](SETUP_AND_DEPLOYMENT.md)**

---

## 🔌 API Documentation

### Endpoints

#### Health Check
```
GET /health
```
Returns: `{"success": true, "data": {"status": "healthy", ...}}`

#### Upload Reviews
```
POST /upload
Content-Type: multipart/form-data
Body: file (CSV with "review" column)
```
Returns: `{"success": true, "data": {"job_id": "...", "reviews_processed": 100}, ...}`

#### Get Analytics
```
GET /insights
```
Returns: 
```json
{
  "success": true,
  "data": {
    "total_reviews": 100,
    "sentiment": {"positive": 45, "negative": 25, "neutral": 30},
    "issues": [
      {"topic": "battery", "frequency": 8, "severity": "high"},
      ...
    ],
    "top_keywords": ["battery", "performance", "camera", ...],
    "ai_insights": {
      "what_users_love": ["performance", "camera"],
      "main_complaints": ["battery", "heating"],
      "summary": "Users appreciate performance but complain about battery life..."
    }
  },
  "message": "Insights generated successfully."
}
```

#### Reset Database (Development)
```
DELETE /reset
```

---

## 📊 CSV Format

Upload a CSV file with a **"review"** column:

```csv
review
"Amazing phone! Great camera quality."
"Battery drains too fast."
"Software updates are slow."
```

**Requirements:**
- Column name: `review` (case-insensitive)
- No empty rows
- Max file size: 10MB (configurable)

---

## 🐛 Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| "Connection refused" on app startup | Ensure backend is running: `uvicorn backend.main:app --reload` |
| Android emulator can't reach backend | Use `http://10.0.2.2:8000` or your machine IP |
| MongoDB connection failed | Start MongoDB or update `MONGO_URI` in `.env` |
| CSV upload fails | Ensure CSV has "review" column (case-insensitive) |
| CORS errors | Set `CORS_ORIGINS=*` in `.env` (dev) or specific domains (prod) |

See [SETUP_AND_DEPLOYMENT.md](SETUP_AND_DEPLOYMENT.md#troubleshooting-connection-issues) for detailed troubleshooting.

---

## 🧪 Testing

### Unit Tests
```bash
# Backend tests
pytest app/tests/

# Frontend tests  
flutter test
```

### Integration Testing
1. Start backend: `uvicorn backend.main:app --reload`
2. Start frontend: `flutter run`
3. Upload `sample_reviews.csv` via the app
4. Verify insights appear in dashboard

### Load Testing
```bash
# Using Apache Bench
ab -n 100 -c 10 http://localhost:8000/insights

# Or using wrk
wrk -t 4 -c 100 -d 30s http://localhost:8000/insights
```

---

## 🚀 Deployment

### Quick Docker Deployment

```bash
# Build
docker build -t insighthub-api .

# Run
docker run -e MONGO_URI=mongodb://mongo:27017 \
           -e DEBUG=false \
           -p 8000:8000 insighthub-api
```

### Production Checklist

- [ ] MongoDB Atlas cluster created (or self-hosted)
- [ ] Backend `.env` configured with production values
- [ ] `DEBUG=false` in `.env`
- [ ] `CORS_ORIGINS` set to specific domain(s)
- [ ] HTTPS/SSL certificates installed
- [ ] Flutter frontend built for release
- [ ] Rate limiting configured
- [ ] Database backups enabled
- [ ] Monitoring & alerting set up

---

## 📈 Features Roadmap

- [ ] User authentication & authorization
- [ ] Multi-tenant support
- [ ] Advanced dashboard widgets
- [ ] Export analytics to PDF
- [ ] Real-time WebSocket updates
- [ ] Custom sentiment models (VADER, BERT)
- [ ] More languages support
- [ ] API rate limiting
- [ ] Admin dashboard
- [ ] Scheduled report generation

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 💬 Support

- **Documentation**: [SETUP_AND_DEPLOYMENT.md](SETUP_AND_DEPLOYMENT.md)
- **Issues**: [GitHub Issues](https://github.com/yourrepo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourrepo/discussions)

---

## 🎓 Learn More

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [TextBlob Sentiment Analysis](https://textblob.readthedocs.io/)

---

<div align="center">

**Made with ❤️ by the InsightHub Team**

**Version 2.0.0** | Last Updated: April 2026

</div>
=======
# EN23CS304053
>>>>>>> 3a671b57fe5572830e7215dd8f46439ce5ae8b8a
