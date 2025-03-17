# Vital Score iOS App

## 📌 Overview
Body Score is an iOS application that calculates a **Body Score (0–100)** based on Apple Health data. The score reflects overall physical well-being, fitness, and body composition. It adapts dynamically to missing data and provides a confidence score based on available health metrics.

## 🚀 Features
- 📊 **HealthKit Integration** – Reads Apple Health metrics (body fat, VO₂ max, heart rate, steps, etc.).
- 🔢 **Body Score Calculation** – Uses weighted scoring based on age, gender, and available data.
- 📈 **Data Visualization** – Shows trends and breakdowns with Swift Charts.
- 🎯 **Customizable Priorities** – Users can adjust metric importance (e.g., weight loss focus).
- 🏆 **Confidence Score** – Indicates completeness of available health data.
- 📅 **History Tracking** – Stores previous scores for trend analysis.
- ✅ **Privacy First** – All health data stays on-device.

## 🛠️ Tech Stack
- **Language**: Swift
- **Framework**: SwiftUI
- **Health Data**: HealthKit
- **State Management**: SwiftData (or CoreData)
- **Charting**: Swift Charts
- **Local Storage**: SwiftData / JSON

## 📲 Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/your-repo/body-score-ios.git
   cd body-score-ios
   ```
2. Open in Xcode:
   ```sh
   open BodyScore.xcodeproj
   ```
3. Run the app on an iOS simulator or device.

## 🔐 Health Data Permissions
The app requests the following Apple Health permissions:
- **Body Composition**: Body Fat %, Lean Body Mass, BMI
- **Fitness & Activity**: VO₂ Max, Steps, Workouts, Active Calories
- **Heart & Vitals**: Resting HR, HRV, Blood Oxygen, BP
- **Metabolic Health**: BMR, Blood Glucose (if available)
- **Optional**: Sleep, Hydration, Stress Levels

> ⚠️ **Data remains on your device and is never shared.**

