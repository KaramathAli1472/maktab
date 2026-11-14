import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Signaling {
  FirebaseFirestore db = FirebaseFirestore.instance;
  String? _roomId;

  Map<String, dynamic> _configurationServer = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  late RTCPeerConnection _rtcPeerConnection;
  late MediaStream _localStream;

  // CallScreen se set hote hain
  late Function(MediaStream stream) onLocalStream;
  late Function(MediaStream stream) onAddRemoteStream;
  late Function() onRemoveRemoteStream;
  late Function() onDisconnect;

  // getter taake CallScreen local stream access kar sake
  MediaStream? get localStream => _localStream;

  // roomIdFromApp = tumhara meeting code (e.g. RSSSSS)
  Future<String?> createRoom(String roomIdFromApp) async {
    final roomRef = db.collection('rooms').doc(roomIdFromApp);
    _roomId = roomRef.id;
    print('Signaling.createRoom: using roomId=$_roomId');

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    onLocalStream.call(_localStream);

    _rtcPeerConnection = await createPeerConnection(_configurationServer);
    registerPeerConnectionListeners();

    _localStream.getTracks().forEach((track) {
      _rtcPeerConnection.addTrack(track, _localStream);
    });

    // caller ICE candidates
    final callerCandidatesCollection = roomRef.collection('callerCandidates');

    _rtcPeerConnection.onIceCandidate = (candidate) {
      if (candidate == null) {
        print('Got final candidate!');
        return;
      }
      final candidateMap = candidate.toMap();
      print('Got candidate: $candidateMap');
      callerCandidatesCollection.add(candidateMap);
    };

    // create offer
    final offer = await _rtcPeerConnection.createOffer(offerSdpConstraints);
    await _rtcPeerConnection.setLocalDescription(offer);
    print('Created offer: ${offer.toMap()}');

    final roomWithOffer = {'offer': offer.toMap()};
    await roomRef.set(roomWithOffer);
    print('New room created with SDP offer. Room ID: ${roomRef.id}');

    _rtcPeerConnection.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');
      onAddRemoteStream.call(event.streams[0]);
    };

    // listen for answer
    roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null && data.containsKey('answer')) {
        print('Got remote description: ${data["answer"]}');
        final rtcSessionDescription = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _rtcPeerConnection.setRemoteDescription(rtcSessionDescription);
      }
    });

    // listen for callee ICE candidates
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          print('Got new remote ICE candidate: $data');
          await _rtcPeerConnection.addCandidate(
            RTCIceCandidate(
              data?['candidate'],
              data?['sdpMid'],
              data?['sdpMlineIndex'],
            ),
          );
        }
      }
    });

    return _roomId;
  }

  Future<void> joinRoomById(String roomId) async {
    _roomId = roomId;
    print('Join room: $_roomId');
    final roomRef = db.collection('rooms').doc(_roomId);
    final roomSnapshot = await roomRef.get();
    print('Got room: ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $_configurationServer');

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      onLocalStream.call(_localStream);

      _rtcPeerConnection = await createPeerConnection(_configurationServer);
      registerPeerConnectionListeners();

      _localStream.getTracks().forEach((MediaStreamTrack track) {
        _rtcPeerConnection.addTrack(track, _localStream);
      });

      // callee ICE candidates
      final calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      _rtcPeerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate == null) {
          print('Got final candidate!');
          return;
        }
        print('Got candidate: ${candidate.candidate}');
        calleeCandidatesCollection.add(candidate.toMap());
      };

      _rtcPeerConnection.onTrack = (RTCTrackEvent event) {
        print('Got remote track: ${event.streams[0]}');
        if (event.track.kind == 'video') {
          onAddRemoteStream.call(event.streams[0]);
        }
      };

      // create answer
      final offer = roomSnapshot.data()?['offer'];
      print('Got offer: $offer');
      await _rtcPeerConnection.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      final RTCSessionDescription answer =
      await _rtcPeerConnection.createAnswer(offerSdpConstraints);
      print('Created answer: ${answer.toMap()}');
      await _rtcPeerConnection.setLocalDescription(answer);

      final roomWithAnswer = {'answer': answer.toMap()};
      await roomRef.update(roomWithAnswer);

      // listen for caller ICE candidates
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            print('Got new remote ICE candidate: $data');
            _rtcPeerConnection.addCandidate(
              RTCIceCandidate(
                data?['candidate'],
                data?['sdpMid'],
                data?['sdpMlineIndex'],
              ),
            );
          }
        }
      });
    }
  }

  void muteMic() {
    try {
      bool enabled = _localStream.getAudioTracks()[0].enabled;
      _localStream.getAudioTracks()[0].enabled = !enabled;
    } catch (_) {}
  }

  // CAMERA SWITCH: front <-> back
  Future<bool> switchCamera() async {
    try {
      final videoTracks = _localStream.getVideoTracks();
      if (videoTracks.isEmpty) return true;
      final track = videoTracks[0];
      final isFront = await Helper.switchCamera(track); // returns bool on new versions
      return isFront;
    } catch (e) {
      print('switchCamera error: $e');
      // agar bool return na kare version me to manually flip kar dena
      return true;
    }
  }

  // safe hangup
  Future<void> hungUp() async {
    try {
      _localStream.getTracks().forEach((track) {
        track.stop();
      });
    } catch (_) {}

    try {
      onRemoveRemoteStream();
    } catch (_) {}

    try {
      await _rtcPeerConnection.close();
    } catch (_) {}

    if (_roomId != null) {
      final roomRef = db.collection('rooms').doc(_roomId);
      try {
        final calleeCandidates =
        await roomRef.collection('calleeCandidates').get();
        for (var candidate in calleeCandidates.docs) {
          await candidate.reference.delete();
        }
        final callerCandidates =
        await roomRef.collection('callerCandidates').get();
        for (var candidate in callerCandidates.docs) {
          await candidate.reference.delete();
        }
        await roomRef.delete();
      } catch (_) {}
    }
  }

  void registerPeerConnectionListeners() {
    _rtcPeerConnection.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    _rtcPeerConnection.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
      if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        try {
          _localStream.getTracks().forEach((track) {
            track.stop();
          });
        } catch (_) {}

        try {
          onRemoveRemoteStream();
        } catch (_) {}

        try {
          _rtcPeerConnection.close();
        } catch (_) {}

        try {
          onDisconnect();
        } catch (_) {}
      }
    };

    _rtcPeerConnection.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    _rtcPeerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state change: $state');
    };
  }
}
