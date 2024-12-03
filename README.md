# Sentry

<p align="left">
  <img src="https://github.com/jonathanvieri/Sentry/blob/main/images/applogo.png" width="150" height="150" >
</p>

<p>
  Sentry is a simple mock CCTV app designed to demonstrate real-time object detection using a live camera feed. Powered by Vision and Core ML frameworks, Sentry uses the lightweight YOLOv3Tiny model to detect and classify objects, displaying bounding boxes and confidence scores.
</p>

<p>
  In addition to live detection, Sentry includes functionality for playing videos from the user's library or a given URL. This project serves as a learning exercise to integrate machine learning models into iOS apps while deepening knowledge of AVFoundation, Vision, and PhotoKit frameworks.
</p>

## Screenshots
<p align="left">
  <img src="https://github.com/jonathanvieri/Sentry/blob/main/images/home-screen.png" height="400">
  &emsp;&emsp;
  <img src="https://github.com/jonathanvieri/Sentry/blob/main/images/live-camera-screen.png" height="400">
</p>
<br>
<p align="left">
  <img src="https://github.com/jonathanvieri/Sentry/blob/main/images/upload-screen.png" height="400">
  &emsp;&emsp;
  <img src="https://github.com/jonathanvieri/Sentry/blob/main/images/video-player-screen.png" height="400">
</p>

## Features
- **Live Object Detection**: Detects and classifies objects in real time using a live camera feed, displaying bounding boxes and confidence scores.
- **Video Playback**: Lets users play videos from their library or a given URL, showcasing AVFoundation's video handling capabilities.
- **Core ML Integration**: Uses the YOLOv3Tiny model for on-device object detection, balancing performance and speed.
- **Interactive Overlays**: Displays bounding boxes and labels that update dynamically during live object detection.
- **Learning-Focused**: A hands-on project to explore AVFoundation, Vision, Core ML, and PhotoKit frameworks.

## Technical Overview
- **Vision Framework**: Handles object detection by processing live camera frames and detecting objects using the YOLOv3Tiny Core ML model.
- **Core ML**: Integrates the YOLOv3Tiny model for on-device object classification and bounding box predictions.
- **AVFoundation**: Manages live camera capture for real-time detection and provides video playback functionality for files from the library or URLs.
- **PhotoKit**: Enables the user to select videos from the photo library for playback through AVFoundation.
- **UIKit**: Implements the user interface, including layouts for live detection and video playback.

## Usage
1. **Live Object Detection**: Launch the app and choose "Camera" to start the live camera feed. The app detects and classifies objects in real time, displaying bounding boxes and confidence scores on the screen.
2. **Play Videos from Library**: Tap "Upload" and select "Upload from Library." Choose a video from your library, and it will play within the app.
3. **Play Videos from URL**: Tap "Upload" and select "Upload from URL." Enter a video URL, and the app will stream and play the video.

## License
This project is licensed under the [MIT License](https://github.com/jonathanvieri/Sentry/blob/main/LICENSE)
