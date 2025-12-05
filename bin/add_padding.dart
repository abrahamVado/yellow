import 'dart:io';
import 'package:image/image.dart';

void main() async {
  const inputPath = 'assets/images/logo.jpeg';
  const outputPath = 'assets/images/logo_padded.jpeg';
  const paddingRatio = 0.4; // 40% padding

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Input file not found: $inputPath');
    exit(1);
  }

  print('Reading image from $inputPath...');
  final image = decodeImage(inputFile.readAsBytesSync());

  if (image == null) {
    print('Failed to decode image');
    exit(1);
  }

  final originalWidth = image.width;
  final originalHeight = image.height;

  // Calculate new size (keeping aspect ratio)
  // We want the original image to be (1 - paddingRatio) of the canvas
  final scaleFactor = 1.0 - paddingRatio;
  final newWidth = (originalWidth * scaleFactor).round();
  final newHeight = (originalHeight * scaleFactor).round();

  print('Resizing image to ${newWidth}x$newHeight...');
  final resizedImage = copyResize(
    image,
    width: newWidth,
    height: newHeight,
    interpolation: Interpolation.cubic,
  );

  // Create new background (black)
  final background = Image(
    width: originalWidth,
    height: originalHeight,
    numChannels: 3, // RGB
  );
  // Fill with #fafafa (250, 250, 250)
  fill(background, color: ColorRgb8(250, 250, 250));

  // Calculate position to center
  final xOffset = (originalWidth - newWidth) ~/ 2;
  final yOffset = (originalHeight - newHeight) ~/ 2;

  // Paste resized image onto background
  print('Compositing image...');
  compositeImage(
    background,
    resizedImage,
    dstX: xOffset,
    dstY: yOffset,
  );

  // Save
  print('Saving to $outputPath...');
  File(outputPath).writeAsBytesSync(encodeJpg(background, quality: 95));
  print('Successfully created padded icon at $outputPath');
}
