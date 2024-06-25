import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../face_camera.dart';
import 'controllers/face_camera_state.dart';
import 'paints/face_painter.dart';
import 'res/builders.dart';

class SmartFaceCamera extends StatefulWidget {
  /// Set false to hide all controls.
  final bool showControls;

  /// Set false to hide capture control icon.
  final bool showCaptureControl;

  /// Set false to hide flash control control icon.
  final bool showFlashControl;

  /// Set false to hide camera lens control icon.
  final bool showCameraLensControl;

  /// Use this pass a message above the camera.
  final String? message;

  /// Style applied to the message widget.
  final TextStyle messageStyle;

  /// Use this to build custom widgets for capture control.
  final CaptureControlBuilder? captureControlBuilder;

  /// Use this to render a custom widget for camera lens control.
  final Widget? lensControlIcon;

  /// Use this to build custom widgets for flash control based on camera flash mode.
  final FlashControlBuilder? flashControlBuilder;

  /// Use this to build custom messages based on face position.
  final MessageBuilder? messageBuilder;

  /// Use this to change the shape of the face indicator.
  final IndicatorShape indicatorShape;

  /// Use this to pass an asset image when IndicatorShape is set to image.
  final String? indicatorAssetImage;

  /// Use this to build custom widgets for the face indicator
  final IndicatorBuilder? indicatorBuilder;

  /// Set true to automatically disable capture control widget when no face is detected.
  final bool autoDisableCaptureControl;

  /// The controller for the [SmartFaceCamera] widget.
  // final FaceCameraController controller;

  /// Callback invoked when camera captures image.
  final void Function(File? image) onCapture;

  Widget backBtn;

  SmartFaceCamera(
      {this.showControls = false,
      this.showCaptureControl = false,
      this.showFlashControl = false,
      this.showCameraLensControl = false,
      this.message,
      this.messageStyle = const TextStyle(
          fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
      this.captureControlBuilder,
      this.lensControlIcon,
      this.flashControlBuilder,
      this.messageBuilder,
      this.indicatorShape = IndicatorShape.defaultShape,
      this.indicatorAssetImage,
      this.indicatorBuilder,
      required this.onCapture,
      this.backBtn = const SizedBox.shrink(),
      this.autoDisableCaptureControl = false,
      super.key})
      : assert(
            indicatorShape != IndicatorShape.image ||
                indicatorAssetImage != null,
            'IndicatorAssetImage must be provided when IndicatorShape is set to image.');

  @override
  State<SmartFaceCamera> createState() => SmartFaceCameraState();
}

class SmartFaceCameraState extends State<SmartFaceCamera>
    with WidgetsBindingObserver {
  Face? _face;
  File? _image;

  ///
  late FaceCameraController controller;

  ///
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller = FaceCameraController(
      autoCapture: true,
      defaultCameraLens: CameraLens.front,
      onCapture: (image) {
        if (mounted) {
          setState(() {
            _image = image;
          });
        }
        widget.onCapture(image);
      },
      onFaceDetected: (Face? face) {
        if (mounted) {
          setState(() {
            _face = face;
          });
        }
      },
    )..initialize();
  }

  void onDispose() {
    try {
      controller.dispose();
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
      controller.dispose();
    } catch (e) {
      print(e);
    } finally {
      super.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.inactive) {
        controller.dispose();
      } else if (state == AppLifecycleState.paused) {
        controller.dispose();
      } else if (state == AppLifecycleState.resumed) {
        initState();
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ValueListenableBuilder<FaceCameraState>(
      valueListenable: controller,
      builder: (BuildContext context, FaceCameraState value, Widget? child) {
        final CameraController? cameraController =
            value.cameraController ?? controller.value.cameraController;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (cameraController != null &&
                cameraController.value.isInitialized) ...[
              Transform.scale(
                scale: 1.0,
                child: AspectRatio(
                  aspectRatio: size.aspectRatio,
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: SizedBox(
                        width: size.width,
                        height: size.width * cameraController.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            _cameraDisplayWidget(value),
                            if (value.detectedFace != null &&
                                widget.indicatorShape != IndicatorShape.none)
                              ...(value.faces
                                      ?.map(
                                        (face) => SizedBox(
                                          width: cameraController
                                              .value.previewSize!.width,
                                          height: cameraController
                                              .value.previewSize!.height,
                                          child: widget.indicatorBuilder?.call(
                                                  context,
                                                  DetectedFace(
                                                      face: face,
                                                      wellPositioned: false),
                                                  Size(
                                                    cameraController.value
                                                        .previewSize!.height,
                                                    cameraController.value
                                                        .previewSize!.width,
                                                  )) ??
                                              CustomPaint(
                                                painter: FacePainter(
                                                    face: face,
                                                    closeEnough: ((widget
                                                                .messageBuilder
                                                                ?.call(
                                                                    context,
                                                                    value
                                                                        .detectedFace) ==
                                                            null) &&
                                                        controller.value.faces
                                                                ?.length ==
                                                            1),
                                                    indicatorShape:
                                                        widget.indicatorShape,
                                                    indicatorAssetImage: widget
                                                        .indicatorAssetImage,
                                                    imageSize: Size(
                                                      cameraController.value
                                                          .previewSize!.height,
                                                      cameraController.value
                                                          .previewSize!.width,
                                                    )),
                                              ),
                                        ),
                                      )
                                      .toList() ??
                                  [])
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: size.width,
                  height: size.height * 0.15,
                  padding: EdgeInsets.only(top: 20),
                  color: const Color.fromARGB(116, 0, 0, 0),
                  child: Row(
                    children: [widget.backBtn],
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.2,
                child: const Align(
                  alignment: Alignment.center,
                  child: AspectRatioOptionsBtnGrp(
                    setActiveAspectRatioOption: print,
                    activeAspectRatioOption: PortraitAspectRatio.a916,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.2,
                  color: Colors.black54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: (controller.value.detectedFace?.comment != null)
                            ? Text(controller.value.detectedFace?.comment ?? 'Please move closer')
                            : (widget.messageBuilder
                                    ?.call(context, value.detectedFace)) ??
                                ((controller.value.faces?.isEmpty == true
                                    ? const Text(
                                        'Please ensure there is at least one face on frame')
                                    : ((controller.value.faces?.length ?? 0) >
                                            1)
                                        ? const Text(
                                            'Please ensure only one face is in frame')
                                        : null)) ??
                                const SizedBox.shrink(),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const CircleSecondaryCameraBtn.icon(
                              icon: Icons.done_rounded,
                              iconColor: Color.fromARGB(93, 193, 193, 193),
                            ),
                            IOSCameraButton(
                              onTap: ((widget.messageBuilder?.call(
                                              context, value.detectedFace) ==
                                          null) &&
                                      controller.value.faces?.length == 1)
                                  ? controller.onTakePictureButtonPressed
                                  : () {},
                            ),
                            const CircleSecondaryCameraBtn.icon(
                              icon: Icons.flip_camera_android,
                              iconColor: Color.fromARGB(93, 193, 193, 193),
                            ),
                          ]),
                    ],
                  ),
                ),
              )
            ] else ...[
              const Text(
                'No Camera Detected',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Render camera.
  Widget _cameraDisplayWidget(FaceCameraState value) {
    final CameraController? cameraController = value.cameraController;
    if (cameraController != null && cameraController.value.isInitialized) {
      return CameraPreview(cameraController, child: Builder(builder: (context) {
        if (controller.value.detectedFace?.comment != null) {
          return Text(controller.value.detectedFace?.comment ?? 'Please move closer');
        }

        if (widget.messageBuilder != null) {
          return (widget.messageBuilder?.call(context, value.detectedFace)) ??
              ((controller.value.faces?.isEmpty == true
                  ? const Text(
                      'Please ensure there is at least one face on frame')
                  : ((controller.value.faces?.length ?? 0) > 1)
                      ? const Text('Please ensure only one face is in frame')
                      : null)) ??
              const SizedBox.shrink();
        }

        if (widget.message != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
            child: Text(widget.message!,
                textAlign: TextAlign.center, style: widget.messageStyle),
          );
        }
        return const SizedBox.shrink();
      }));
    }
    return const SizedBox.shrink();
  }

  /// Determines when to disable the capture control button.
  bool get _disableCapture =>
      widget.autoDisableCaptureControl &&
      controller.value.detectedFace?.face == null;

  /// Determines the camera controls color.
  Color? get iconColor =>
      controller.enableControls ? null : Theme.of(context).disabledColor;

  /// Display the control buttons to take pictures.
  Widget _captureControlWidget(FaceCameraState value) {
    return IconButton(
      icon: widget.captureControlBuilder?.call(context, value.detectedFace) ??
          CircleAvatar(
              radius: 35,
              foregroundColor: controller.enableControls && !_disableCapture
                  ? null
                  : Theme.of(context).disabledColor,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.camera_alt, size: 35),
              )),
      onPressed: controller.enableControls && !_disableCapture
          ? controller.onTakePictureButtonPressed
          : null,
    );
  }
}

enum PortraitAspectRatio {
  a23(2 / 3),
  a916(9 / 16),
  a45(4 / 5);
  // a11(1 / 1);

  const PortraitAspectRatio(this.value);

  final double value;

  @override
  String toString() => switch (this) {
        PortraitAspectRatio.a916 => '9:16',
        PortraitAspectRatio.a23 => '2:3',
        PortraitAspectRatio.a45 => '4:5',
        _ => '1:1'
      };

  double toDouble() => switch (this) {
        PortraitAspectRatio.a916 => PortraitAspectRatio.a916.value,
        PortraitAspectRatio.a23 => PortraitAspectRatio.a916.value,
        PortraitAspectRatio.a45 => PortraitAspectRatio.a916.value,
        _ => PortraitAspectRatio.a916.value
      };
}

class CircleSecondaryCameraBtn extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final double size;
  final double scale;
  final Color? iconColor;
  final Color? bgColor;

  const CircleSecondaryCameraBtn.icon({
    super.key,
    this.size = 50.0,
    required IconData this.icon,
    this.scale = 1.0,
    this.iconColor,
    this.bgColor,
  }) : child = null;

  const CircleSecondaryCameraBtn({
    super.key,
    this.size = 50.0,
    required Widget this.child,
    this.scale = 1.3,
    this.iconColor,
    this.bgColor,
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: buttonTheme.shape,
      color: bgColor ?? buttonTheme.backgroundColor,
      child: Padding(
        padding: buttonTheme.padding * scale,
        child: child ??
            Icon(
              icon,
              color: iconColor ?? buttonTheme.foregroundColor,
              size: buttonTheme.iconSize * scale,
            ),
      ),
    );
  }
}

final buttonTheme = _SecondaryCameraButtonTheme();

class _SecondaryCameraButtonTheme {
  final Color foregroundColor;
  final Color backgroundColor;
  final double iconSize;
  final EdgeInsets padding;
  final ShapeBorder shape;
  final bool rotateWithCamera;
  static const double baseIconSize = 25;

  _SecondaryCameraButtonTheme({
    this.foregroundColor = Colors.white,
    this.backgroundColor = Colors.black12,
    this.iconSize = baseIconSize,
    this.padding = const EdgeInsets.all(12),
    this.shape = const CircleBorder(),
    this.rotateWithCamera = true,
  });
}

class IOSCameraButton extends StatelessWidget {
  final VoidCallback onTap;
  const IOSCameraButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72.0,
        height: 72.0,
        decoration: const BoxDecoration(
          color: Color.fromARGB(70, 237, 237, 237),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(90, 222, 222, 222),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AspectRatioOptionsBtnGrp extends StatelessWidget {
  final PortraitAspectRatio activeAspectRatioOption;

  final void Function(PortraitAspectRatio) setActiveAspectRatioOption;

  const AspectRatioOptionsBtnGrp({
    Key? key,
    required this.activeAspectRatioOption,
    required this.setActiveAspectRatioOption,
  }) : super(key: key);

  Widget _buildAspectRatioOptionsButton(PortraitAspectRatio value) {
    bool isActive = activeAspectRatioOption == value;
    return GestureDetector(
      onTap: () => setActiveAspectRatioOption(value),
      child: AnimatedContainer(
        padding: EdgeInsets.all(isActive ? 10 : 6),
        margin: EdgeInsets.symmetric(horizontal: isActive ? 4 : 2),
        duration: const Duration(milliseconds: 250),
        width: isActive ? 60 : 40,
        decoration: BoxDecoration(
            color: buttonTheme.backgroundColor,
            borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: isActive ? Colors.amber[700] : Colors.white,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: buttonTheme.backgroundColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: PortraitAspectRatio.values
                .map(_buildAspectRatioOptionsButton)
                .toList(),
          ),
        ),
      ),
    );
  }
}
