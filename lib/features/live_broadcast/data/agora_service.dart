import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/models.dart';

/// Agora RTC SDK service for real-time video broadcasting
///
/// Credentials are passed via --dart-define at build time:
///   flutter run --dart-define=AGORA_APP_ID=xxx --dart-define=AGORA_TEMP_TOKEN=xxx
class AgoraService {
  static const String _appId = String.fromEnvironment('AGORA_APP_ID');

  // Token should be generated server-side via Cloud Function in production
  static const String _tempToken = String.fromEnvironment('AGORA_TEMP_TOKEN', defaultValue: '');
  static const String _testChannel = 'test123';

  RtcEngine? _engine;
  bool _isInitialized = false;

  // Remote user tracking
  int? _remoteUid;
  final ValueNotifier<int?> remoteUidNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<bool> localVideoReady = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  int? get remoteUid => _remoteUid;

  /// Initialize the Agora engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_appId.isEmpty) {
      throw Exception('AGORA_APP_ID not set. Pass via --dart-define=AGORA_APP_ID=xxx');
    }

    debugPrint('[AgoraService] Initializing Agora engine...');

    try {
      _engine = createAgoraRtcEngine();
      debugPrint('[AgoraService] Engine created: $_engine');

      if (_engine == null) {
        throw Exception('createAgoraRtcEngine returned null - Agora Web SDK may not be loaded');
      }

      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      debugPrint('[AgoraService] Engine initialized with appId');

      _registerEventHandlers();
      await _engine!.enableVideo();
      debugPrint('[AgoraService] Video enabled');

      _isInitialized = true;
      debugPrint('[AgoraService] Agora engine fully ready');
    } catch (e, stackTrace) {
      debugPrint('[AgoraService] INIT ERROR: $e');
      debugPrint('[AgoraService] Stack: $stackTrace');
      _engine = null;
      rethrow;
    }
  }

  void _registerEventHandlers() {
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint('[AgoraService] Joined channel: ${connection.channelId}, uid: ${connection.localUid}');
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint('[AgoraService] Remote user joined: $remoteUid');
        _remoteUid = remoteUid;
        remoteUidNotifier.value = remoteUid;
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint('[AgoraService] Remote user offline: $remoteUid, reason: $reason');
        if (_remoteUid == remoteUid) {
          _remoteUid = null;
          remoteUidNotifier.value = null;
        }
      },
      onLocalVideoStateChanged: (VideoSourceType source, LocalVideoStreamState state, LocalVideoStreamReason reason) {
        debugPrint('[AgoraService] Local video state: $state, reason: $reason');
        localVideoReady.value = state == LocalVideoStreamState.localVideoStreamStateCapturing ||
            state == LocalVideoStreamState.localVideoStreamStateEncoding;
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint('[AgoraService] ERROR: $err - $msg');
        errorNotifier.value = 'Agora hatasi: $msg';
      },
    ));
  }

  /// Join channel as broadcaster (camera + microphone)
  Future<void> joinAsBroadcaster(String channelName) async {
    if (!_isInitialized) await initialize();

    // Use test channel for temp token testing
    final channel = _testChannel;
    debugPrint('[AgoraService] Joining as broadcaster: $channel (original: $channelName)');

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: _tempToken,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  /// Join channel as audience (view only)
  Future<void> joinAsAudience(String channelName) async {
    if (!_isInitialized) await initialize();

    // Use test channel for temp token testing
    final channel = _testChannel;
    debugPrint('[AgoraService] Joining as audience: $channel (original: $channelName)');

    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

    await _engine!.joinChannel(
      token: _tempToken,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        clientRoleType: ClientRoleType.clientRoleAudience,
      ),
    );
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    debugPrint('[AgoraService] Leaving channel');
    _remoteUid = null;
    remoteUidNotifier.value = null;
    localVideoReady.value = false;

    try {
      await _engine?.leaveChannel();
    } catch (e) {
      debugPrint('[AgoraService] Error leaving channel: $e');
    }
  }

  bool _isFrontCamera = true;

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_engine == null) return;
    debugPrint('[AgoraService] Switching camera (web=$kIsWeb)');

    try {
      if (kIsWeb) {
        // Web'de switchCamera desteklenmiyor, video source degistiriyoruz
        _isFrontCamera = !_isFrontCamera;
        await _engine!.stopPreview();

        final cameraDirection = _isFrontCamera
            ? CameraDirection.cameraFront
            : CameraDirection.cameraRear;

        // Web'de kamera degistirmek icin video device'i yeniden ayarla
        try {
          await _engine!.setCameraCapturerConfiguration(
            CameraCapturerConfiguration(
              cameraDirection: cameraDirection,
            ),
          );
        } catch (e) {
          debugPrint('[AgoraService] setCameraCapturerConfiguration failed: $e');
        }

        await _engine!.startPreview();
        debugPrint('[AgoraService] Camera switched to: ${_isFrontCamera ? "front" : "rear"}');
      } else {
        await _engine!.switchCamera();
      }
    } catch (e) {
      debugPrint('[AgoraService] Switch camera error: $e');
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  /// Set video encoder config based on StreamQuality
  Future<void> setVideoQuality(StreamQuality quality) async {
    if (!_isInitialized) return;

    final config = _getVideoConfig(quality);
    await _engine!.setVideoEncoderConfiguration(config);
    debugPrint('[AgoraService] Video quality set to: ${quality.displayName}');
  }

  VideoEncoderConfiguration _getVideoConfig(StreamQuality quality) {
    switch (quality) {
      case StreamQuality.quality1080p:
        return const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1920, height: 1080),
          frameRate: 30,
          bitrate: 4500,
        );
      case StreamQuality.quality720p:
        return const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 2500,
        );
      case StreamQuality.quality480p:
        return const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 854, height: 480),
          frameRate: 24,
          bitrate: 1000,
        );
      case StreamQuality.quality360p:
        return const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 24,
          bitrate: 500,
        );
      case StreamQuality.auto:
        return const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 2500,
          minBitrate: 1000,
        );
    }
  }

  /// Dispose the engine
  Future<void> dispose() async {
    debugPrint('[AgoraService] Disposing Agora engine');
    _remoteUid = null;
    remoteUidNotifier.value = null;
    localVideoReady.value = false;

    if (_isInitialized) {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
      _isInitialized = false;
    }

    remoteUidNotifier.dispose();
    localVideoReady.dispose();
    errorNotifier.dispose();
  }
}
