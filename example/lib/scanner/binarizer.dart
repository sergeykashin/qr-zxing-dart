import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import '../models/image_source.dart';
import '../models/utils.dart';
import '../widgets/cupertino_icon_button.dart';

class BinarizerPage extends StatefulWidget {
  const BinarizerPage({Key? key}) : super(key: key);

  @override
  State<BinarizerPage> createState() => _BinarizerPageState();
}

class _BinarizerPageState extends State<BinarizerPage> {
  BufferImage? bufferImage;
  GrayImage? grayImage;
  GrayImage? deNoiseImage;
  GrayImage? binaryImage;
  GrayImage? hybridBinaryImage;
  GrayImage? inverseImage;

  int imageLoadStatus = 0;

  Future<void> takePicture() async {
    XFile? picture = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return const TakePhoto();
        },
      ),
    );
    if (picture != null) {
      setState(() {
        imageLoadStatus = 1;
      });
      initImage(await picture.readAsBytes());
    }
  }

  Future<void> loadFile() async {
    Uint8List? fileData = await _pickFile();

    if (fileData != null) {
      setState(() {
        imageLoadStatus = 1;
      });
      initImage(fileData);
    } else {
      print('not pick any file');
    }
  }

  Future<void> initImage(Uint8List fileData) async {
    bufferImage = await BufferImage.fromFile(fileData);
    if (bufferImage == null) {
      alert(context, 'Can\'t read the image');
      return;
    }
    setState(() {});
    grayImage = bufferImage?.toGray();
    setState(() {});
    deNoiseImage = grayImage!.copy()
      ..deNoise()
      ..binaryzation()
      ..deNoise();
    setState(() {});
    binaryImage = bin2Image(
      GlobalHistogramBinarizer(ImageLuminanceSource(bufferImage!.copy())),
    );
    setState(() {});
    hybridBinaryImage =
        bin2Image(HybridBinarizer(ImageLuminanceSource(bufferImage!.copy())));
    setState(() {});
    inverseImage = bin2Image(
      GlobalHistogramBinarizer(
        ImageLuminanceSource(bufferImage!.copy()..inverse()),
      ),
    );
    setState(() {
      imageLoadStatus = 2;
    });
  }

  GrayImage bin2Image(Binarizer binarizer) {
    BitMatrix matrix = binarizer.blackMatrix;
    GrayImage image = GrayImage(matrix.width, matrix.height);
    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        image.setChannel(x, y, matrix.get(x, y) ? 0 : 255);
      }
    }
    return image;
  }

  Future<Uint8List?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);

    if (result != null && result.count > 0) {
      return result.files.first.bytes;
    } else {
      // User canceled the picker
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Binarizer'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CupertinoButton.filled(
                    onPressed: () {
                      loadFile();
                    },
                    child: const Text('file...'),
                  ),
                  CupertinoButton.filled(
                    onPressed: () {
                      takePicture();
                    },
                    child: const Text('Camera...'),
                  )
                ],
              ),
              const SizedBox(height: 20),
              if (bufferImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(bufferImage!, scale: 1),
                  ),
                ),
              if (grayImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(grayImage!),
                      scale: 1,
                    ),
                  ),
                ),
              if (deNoiseImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(deNoiseImage!),
                      scale: 1,
                    ),
                  ),
                ),
              if (binaryImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(binaryImage!),
                      scale: 1,
                    ),
                  ),
                ),
              if (hybridBinaryImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(hybridBinaryImage!),
                      scale: 1,
                    ),
                  ),
                ),
              if (inverseImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(inverseImage!),
                      scale: 1,
                    ),
                  ),
                ),
              if (imageLoadStatus == 1) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class TakePhoto extends StatefulWidget {
  const TakePhoto({Key? key}) : super(key: key);

  @override
  State<TakePhoto> createState() => _TakePhotoState();
}

class _TakePhotoState extends State<TakePhoto> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool detectedCamera = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          detectedCamera = true;
        });
      });
    } else {
      setState(() {
        detectedCamera = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    XFile picture = await _controller!.takePicture();
    Navigator.of(context).pop(picture);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Camera'),
      ),
      child: Center(
        child: _controller == null
            ? Text(detectedCamera ? 'Not detected cameras' : 'Detecting')
            : CameraPreview(
                _controller!,
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, 0.7),
                      child: CupertinoIconButton(
                        icon: const Icon(CupertinoIcons.camera),
                        onPressed: takePicture,
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
