import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DetectedFace {
  final Face? face;
  final bool wellPositioned;
  final String? comment;
  const DetectedFace({required this.face, required this.wellPositioned, this.comment});

  DetectedFace copyWith({Face? face, bool? wellPositioned}) => DetectedFace(
      face: face ?? this.face,
      wellPositioned: wellPositioned ?? this.wellPositioned);
}
