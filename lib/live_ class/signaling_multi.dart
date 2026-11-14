import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingMulti {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final String roomId;
  final String selfId; // Firebase UID (teacher / student)

  SignalingMulti({
    required this.roomId,
    required this.selfId,
  });

  // ICE servers
  final Map<String, dynamic> _configurationServer = {
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

  final Map<String, dynamic> _offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  late MediaStream _localStream;
  MediaStream get localStream => _localStream;

  // peerId -> PeerConnection
  final Map<String, RTCPeerConnection> _peerConnections = {};
  // peerId -> remote stream
  final Map<String, MediaStream> _remoteStreams = {};

  // callbacks set from UI
  late void Function(MediaStream stream) onLocalStream;
  late void Function(String peerId, MediaStream stream) onAddRemoteStream;
  late void Function(String peerId) onRemoveRemoteStream;
  late void Function() onDisconnect;

  bool _joined = false;

  // helper: stable connection id (order independent)
  String _connectionId(String a, String b) {
    if (a.compareTo(b) < 0) {
      return '${a}_$b';
    } else {
      return '${b}_$a';
    }
  }

  /// Room join + local stream init + participants listen
  Future<void> joinRoom() async {
    if (_joined) return;
    _joined = true;

    // 1) Local stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    onLocalStream.call(_localStream);

    // 2) Participants collection me khud ko add karo
    final roomRef = db.collection('rooms').doc(roomId);
    final participantsRef = roomRef.collection('participants').doc(selfId);

    await participantsRef.set({
      'userId': selfId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // 3) Existing participants load karo
    final existing = await roomRef.collection('participants').get();
    for (final doc in existing.docs) {
      final otherId = doc.id;
      if (otherId == selfId) continue;
      await _createConnectionAsCaller(otherId);
    }

    // 4) Future participants listen
    roomRef.collection('participants').snapshots().listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        final otherId = change.doc.id;
        if (otherId == selfId) continue;

        if (change.type == DocumentChangeType.added) {
          if (!_peerConnections.containsKey(otherId)) {
            await _createConnectionAsCaller(otherId);
          }
        } else if (change.type == DocumentChangeType.removed) {
          await _closePeer(otherId);
        }
      }
    });

    // 5) Connections collection ke offers/answers/ICE suno
    _listenConnections(roomRef);
  }

  /// Caller side: selfId -> otherId connection create, offer write
  Future<void> _createConnectionAsCaller(String otherId) async {
    final connId = _connectionId(selfId, otherId);
    final roomRef = db.collection('rooms').doc(roomId);
    final connRef = roomRef.collection('connections').doc(connId);

    // Agar already exists & has offer/answer, skip
    final existingConn = await connRef.get();
    if (existingConn.exists) return;

    final pc = await createPeerConnection(_configurationServer);
    _peerConnections[otherId] = pc;

    _registerPeerListeners(otherId, pc, connRef, isCaller: true);

    // local tracks add
    _localStream.getTracks().forEach((track) {
      pc.addTrack(track, _localStream);
    });

    // offer create
    final offer = await pc.createOffer(_offerSdpConstraints);
    await pc.setLocalDescription(offer);

    await connRef.set({
      'from': selfId,
      'to': otherId,
      'offer': offer.toMap(),
    });
  }

  /// Callee side: when connection doc with offer (from != self) appears
  Future<void> _handleIncomingOffer(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final data = doc.data();
    if (data == null) return;

    final fromId = data['from'] as String;
    final toId = data['to'] as String;
    if (toId != selfId) return; // not for me

    // Agar already connection bani hai, skip
    if (_peerConnections.containsKey(fromId)) return;

    final roomRef = db.collection('rooms').doc(roomId);
    final connRef = roomRef.collection('connections').doc(doc.id);

    final pc = await createPeerConnection(_configurationServer);
    _peerConnections[fromId] = pc;

    _registerPeerListeners(fromId, pc, connRef, isCaller: false);

    _localStream.getTracks().forEach((track) {
      pc.addTrack(track, _localStream);
    });

    // remote offer set
    final offerMap = data['offer'] as Map<String, dynamic>;
    final offer = RTCSessionDescription(offerMap['sdp'], offerMap['type']);
    await pc.setRemoteDescription(offer);

    // create answer
    final answer = await pc.createAnswer(_offerSdpConstraints);
    await pc.setLocalDescription(answer);

    await connRef.update({
      'answer': answer.toMap(),
    });
  }

  /// Shared peer connection listeners + ICE handling
  void _registerPeerListeners(
      String peerId,
      RTCPeerConnection pc,
      DocumentReference<Map<String, dynamic>> connRef, {
        required bool isCaller,
      }) {
    final callerCandidatesCollection =
    connRef.collection('callerCandidates');
    final calleeCandidatesCollection =
    connRef.collection('calleeCandidates');

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate == null) return;

      final targetCollection =
      isCaller ? callerCandidatesCollection : calleeCandidatesCollection;
      targetCollection.add(candidate.toMap());
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        final stream = event.streams[0];
        _remoteStreams[peerId] = stream;
        onAddRemoteStream(peerId, stream);
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      print('Peer $peerId connection state: $state');
      if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _closePeer(peerId);
      }
    };
  }

  /// Listen to all connections docs & ICE for me
  void _listenConnections(DocumentReference roomRef) {
    roomRef.collection('connections').snapshots().listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data();
        if (data == null) continue;

        if (change.type == DocumentChangeType.added) {
          // Agar offer me to == selfId hai -> callee side handle
          if (data['to'] == selfId &&
              !(data['answer'] ?? {}).containsKey('sdp')) {
            await _handleIncomingOffer(doc);
          }

          // ICE candidates listen start karo
          _listenIceCandidates(roomRef, doc.id, data);
        } else if (change.type == DocumentChangeType.modified) {
          // answer set hua hai -> caller side remoteDescription set karo
          await _handleAnswerUpdate(data);
        }
      }
    });
  }

  Future<void> _handleAnswerUpdate(Map<String, dynamic> data) async {
    if (!data.containsKey('answer')) return;
    final fromId = data['from'] as String;
    final toId = data['to'] as String;

    // Agar hum caller the (from == selfId), to answer humare liye hai
    if (fromId == selfId) {
      final peerId = toId;
      final pc = _peerConnections[peerId];
      if (pc == null) return;

      final answerMap = data['answer'] as Map<String, dynamic>;
      final answer =
      RTCSessionDescription(answerMap['sdp'], answerMap['type']);
      await pc.setRemoteDescription(answer);
    }
  }

  void _listenIceCandidates(
      DocumentReference roomRef,
      String connId,
      Map<String, dynamic> connData,
      ) {
    final fromId = connData['from'] as String;
    final toId = connData['to'] as String;

    final isCaller = fromId == selfId;
    final peerId = isCaller ? toId : fromId;

    final pc = _peerConnections[peerId];
    if (pc == null) return;

    // Agar hum caller hain -> calleeCandidates suno
    // Agar hum callee hain -> callerCandidates suno
    final remoteCandidatesCollection = roomRef
        .collection('connections')
        .doc(connId)
        .collection(isCaller ? 'calleeCandidates' : 'callerCandidates');

    remoteCandidatesCollection.snapshots().listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMlineIndex'],
          );
          await pc.addCandidate(candidate);
        }
      }
    });
  }

  Future<void> _closePeer(String peerId) async {
    final pc = _peerConnections.remove(peerId);
    if (pc != null) {
      await pc.close();
    }

    final stream = _remoteStreams.remove(peerId);
    if (stream != null) {
      try {
        stream.getTracks().forEach((t) => t.stop());
      } catch (_) {}
    }

    try {
      onRemoveRemoteStream(peerId);
    } catch (_) {}
  }

  Future<void> leaveRoom() async {
    // local tracks stop
    try {
      _localStream.getTracks().forEach((t) => t.stop());
    } catch (_) {}

    // sab peers close
    final peers = List<String>.from(_peerConnections.keys);
    for (final p in peers) {
      await _closePeer(p);
    }

    // participants se khud ko remove karo
    final roomRef = db.collection('rooms').doc(roomId);
    await roomRef.collection('participants').doc(selfId).delete();
  }
}
