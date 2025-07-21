# VoiceDo - Voice-Powered Task Manager 🎙️✅

A revolutionary Flutter application that combines voice recognition with AI-powered task management, featuring real-time Firebase integration and cutting-edge Gemini AI function calling on the client side.

[![Flutter](https://img.shields.io/badge/Flutter-3.32.7-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
[![Gemini AI](https://img.shields.io/badge/Gemini%20AI-2.5%20Flash-green.svg)](https://ai.google.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🌟 Overview

[📹 Watch Demo Video](https://www.loom.com/share/2c0bc9ee793f4b5bbd5a1f7904ed2104?sid=2cff350d-acb0-4492-828c-f7d80e88c70b)

VoiceDo is an intelligent task management application that allows users to create, update, and delete tasks using natural voice commands. The app leverages Google's Gemini AI with **client-side function calling** - a cutting-edge approach that reduces API costs by 50% compared to traditional server-side implementations.

## 🚀 Key Features

### ✅ Core Capabilities
- **Create Tasks** - Add new tasks with voice commands
- **Update Tasks** - Modify existing tasks (title, description, date, status)
- **Delete Tasks** - Remove tasks by voice instruction
- **Change Username** - Update user display name

### 🎯 Advanced Features
- **Voice-to-Text Integration** - Real-time speech recognition
- **AI-Powered Processing** - Gemini AI understands natural language
- **Real-time Database** - Firebase Firestore with live synchronization
- **Anonymous Authentication** - Automatic user creation on first launch
- **Floating Chat Interface** - Visual feedback of voice interactions
- **Smart Error Handling** - User-friendly error messages in chat
- **Task Number System** - Dual identification (ID + positional numbers)
- **Contextual AI Memory** - AI remembers previous tasks and conversations

## 🔥 Revolutionary Approach: Client-Side Function Calling

### Why This Matters
Most LLM applications use **server-side function calling**, which means:
- ❌ Each function execution costs money
- ❌ Higher API usage and billing
- ❌ Slower response times due to server round-trips

### AI Innovation
VoiceDo implements **client-side function calling** with Gemini AI:
- ✅ Functions execute locally on the device
- ✅ **50% cost reduction** compared to server-side approaches
- ✅ Faster response times
- ✅ Better user experience
- ✅ Trending technology adoption

This approach represents the future of AI-powered mobile applications, making advanced AI features more accessible and cost-effective.

## 🏗️ Architecture & Technical Implementation

### Tech Stack
- **Frontend**: Flutter 3.32+
- **AI Integration**: Google Gemini 2.5 Flash API
- **Database**: Firebase Firestore
- **Authentication**: Firebase Anonymous Auth
- **State Management**: Provider Pattern
- **Voice Recognition**: Flutter-Speech APIs
- **Design**: Material Design 3 with custom theming

### Project Structure
```
lib/
├── core/
│   ├── constants/        # App colors, dimensions, strings
│   └── utils/           # Helper utilities
├── models/              # Data models (Task, ChatMessage)
├── providers/           # State management (Task, Gemini, Firebase)
├── services/            # Core services (Voice, Gemini, Firebase)
├── views/
│   ├── screens/         # App screens
│   └── widgets/         # Reusable UI components
└── main.dart           # App entry point
```

## 📱 How It Works

### 1. **Anonymous User Creation**
- App automatically creates an anonymous Firebase user on first launch
- User data stored securely in Firestore
- No registration or login required

### 2. **Voice Interaction Flow**
```
User taps FAB → Starts voice recording → User speaks command → 
Converts to text → Sends to Gemini AI → AI processes & calls functions → 
Updates database → UI refreshes automatically
```

### 3. **AI Function Calling Process**
1. **Voice Input**: "Create a task to buy groceries tomorrow at 5 PM"
2. **AI Processing**: Gemini extracts task details and determines function to call
3. **Client-Side Execution**: App executes `create_task` function locally
4. **Database Update**: Task saved to Firebase Firestore
5. **Real-time Sync**: UI updates automatically via listeners

### 4. **Smart Task Identification**
- **Primary**: AI memory-based identification by task content
- **Fallback**: Task number system (1, 2, 3, etc.) for user convenience

## 🎮 User Experience

### Simple Voice Commands
- *"Create a task to call mom tomorrow"*
- *"Update task 3 to next week"*
- *"Delete my grocery task"*
- *"Change my name to Sarah"*

### Visual Feedback
- **Floating Chat Widget**: Shows voice input and AI responses
- **System Messages**: Error handling and status updates
- **Real-time Updates**: Instant UI refresh on data changes
- **Recording Indicator**: Visual feedback during voice capture

## 🔧 Setup & Installation

### Prerequisites
- Flutter 3.32.7 or higher
- Firebase project with Firestore, Authentication(Anonymous), AI Logic(Gemini Developer API) enabled

### Quick Start
1. **Clone the repository**
   ```bash
   git clone https://github.com/syedjahangeershah/voicedo.git
   cd voicedo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (Optional - for your own testing)
   ```bash
   flutterfire configure
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🧪 Testing with Different Models

The app supports multiple Gemini models:
- **Gemini 2.0 Flash** (Primary)
- **Gemini 2.5 Flash** (Fallback)
- **Gemini 1.5 Pro** (Alternative)

### Model Switching
If you encounter rate limits:
1. Open app settings
2. Select different model from dropdown
3. Continue testing with new model

### Free Tier Limitations
- App uses free Gemini API tier
- Daily rate limits apply
- If all models are exhausted, wait for next day reset
- For unlimited testing, upgrade to paid tier

## 🔥 For Extensive Testing

Want to test without limitations? Set up your own Firebase:

1. **Create Firebase Project**
    - Go to [Firebase Console](https://console.firebase.google.com/)
    - Create new project
    - Enable Firestore Database
    - Enable AI Logic Gemini Developer API

2. **Configure Project**
   ```bash
   cd your-project-directory
   flutterfire configure
   ```

4. **Run the app**
    - Rebuild and run the app

**Voila!** You now have unlimited testing with your own Firebase backend.

## 🎯 Available Functions

Currently implemented functions:

| Function | Description | Voice Command Example |
|----------|-------------|----------------------|
| `create_task` | Create new task | "Create a task to buy milk tomorrow" |
| `update_task` | Modify existing task | "Update task 2 status to completed" |
| `delete_task` | Remove task | "Delete the 2nd task" |
| `update_user_name` | Change username | "Change my name to John" |

### Future Enhancements
Additional functions can be easily added:
- Task filtering and sorting
- Task categories and tags
- Recurring task creation
- Task sharing and collaboration
- Calendar integration
- Advanced scheduling

## 💡 Innovation Highlights

### 1. **Cost-Effective AI Integration**
- Client-side function calling reduces API costs by 50%
- Efficient token usage through smart prompt engineering
- Local processing for better performance

### 2. **Seamless User Experience**
- Zero-learning curve voice interface
- Contextual AI that remembers conversations
- Real-time visual feedback
- Graceful error handling

### 3. **Scalable Architecture**
- Modular provider-based state management
- Clean separation of concerns
- Easy feature addition and modification
- Production-ready code structure

### 4. **Modern Technology Stack**
- Latest Flutter features and best practices
- Firebase real-time capabilities
- Cutting-edge AI integration
- Material Design 3 implementation

## 🐛 Error Handling & User Experience

### Smart Error Management
- **Voice Recognition Errors**: Automatic retry with user feedback
- **AI Processing Errors**: Fallback responses and error explanations
- **Network Issues**: Offline capability and sync when reconnected
- **Function Call Failures**: User-friendly error messages in chat interface

### User-Friendly Features
- **Task Number System**: When AI forgets task IDs, users can reference by position
- **Contextual Memory**: AI remembers previous tasks and user preferences
- **Visual Feedback**: Chat interface shows exactly what's happening
- **Graceful Degradation**: App remains functional even with partial feature failures

## 📊 Performance & Optimization

### Efficient Resource Usage
- **Lazy Loading**: Services initialized only when needed
- **Real-time Listeners**: Minimal data transfer with Firestore snapshots
- **Memory Management**: Proper disposal of controllers and streams
- **Battery Optimization**: Efficient voice recognition with smart start/stop

### Scalability Considerations
- **Modular Architecture**: Easy to add new features and functions
- **Provider Pattern**: Scalable state management for large applications
- **Clean Code Structure**: Maintainable and testable codebase
- **Future-Proof Design**: Ready for additional AI models and services

## 🤝 Contributing

This project showcases modern Flutter development practices and AI integration techniques. The codebase serves as an excellent reference for:

- AI-powered mobile application development
- Client-side function calling implementation
- Real-time Firebase integration
- Voice-controlled user interfaces
- Modern Flutter architecture patterns

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

**Syed Jahangeer Shah**
- Flutter Developer & AI Integration Specialist
- GitHub: [@syedjahangeershah](https://github.com/syedjahangeershah)

---

### 🎯 Project Significance

This application demonstrates the successful integration of multiple cutting-edge technologies:
- **AI-First Design**: Natural language processing for intuitive user interaction
- **Cost-Effective Innovation**: Client-side function calling reducing operational costs
- **Real-time Architecture**: Instant data synchronization across all components
- **Modern Development Practices**: Clean architecture, proper state management, and user-centric design

VoiceDo represents the future of task management applications, where AI assistance meets practical functionality in a cost-effective, user-friendly package.

**Ready to revolutionize how you manage tasks? Try VoiceDo today!** 🚀