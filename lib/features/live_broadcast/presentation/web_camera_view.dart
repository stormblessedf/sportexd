import 'package:flutter/material.dart';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Web platformu için kamera görüntüsü widget'ı
class WebCameraView extends StatefulWidget {
  final Function(bool)? onCameraReady;
  final Function(String)? onError;

  const WebCameraView({
    super.key,
    this.onCameraReady,
    this.onError,
  });

  @override
  State<WebCameraView> createState() => _WebCameraViewState();
}

class _WebCameraViewState extends State<WebCameraView> {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _viewId;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Unique view ID for this camera instance
      _viewId = 'web-camera-${DateTime.now().millisecondsSinceEpoch}';

      // Create video element
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'; // Mirror the video

      // Request camera access
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'user', // Front camera
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': true,
      });

      if (_mediaStream != null) {
        _videoElement!.srcObject = _mediaStream;

        // Register the view
        ui_web.platformViewRegistry.registerViewFactory(
          _viewId!,
          (int viewId) => _videoElement!,
        );

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
          widget.onCameraReady?.call(true);
        }
      } else {
        throw Exception('Kamera erişimi sağlanamadı');
      }
    } catch (e) {
      String errorMsg = 'Kamera başlatılamadı';

      if (e.toString().contains('NotAllowedError')) {
        errorMsg = 'Kamera izni reddedildi. Lütfen tarayıcı ayarlarından izin verin.';
      } else if (e.toString().contains('NotFoundError')) {
        errorMsg = 'Kamera bulunamadı. Lütfen bir kamera bağlayın.';
      } else if (e.toString().contains('NotReadableError')) {
        errorMsg = 'Kamera başka bir uygulama tarafından kullanılıyor.';
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = errorMsg;
        });
        widget.onError?.call(errorMsg);
        widget.onCameraReady?.call(false);
      }
    }
  }

  Future<void> _switchCamera() async {
    // Stop current stream
    _stopCamera();

    try {
      // Request camera with different facing mode
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'environment', // Back camera
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': true,
      });

      if (_mediaStream != null && _videoElement != null) {
        _videoElement!.srcObject = _mediaStream;
        setState(() {});
      }
    } catch (e) {
      // If back camera not available, try front again
      _initCamera();
    }
  }

  void _stopCamera() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _videoElement?.srcObject = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 80, color: Colors.white30),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? 'Kamera hatası',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _viewId == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Kamera başlatılıyor...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Tarayıcı izin isteyebilir',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewId!),
        // Camera switch button
        Positioned(
          top: 60,
          right: 16,
          child: IconButton(
            onPressed: _switchCamera,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
