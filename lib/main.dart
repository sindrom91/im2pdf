import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image to PDF converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<File> pickedImages = [];
  int selectedIndex = -1;

  static const permissionError = SnackBar(
    content: const Text('No permission to write to local storage'),
    duration: const Duration(seconds: 2),
  );

  static const conversionSuccessful = SnackBar(
    content: const Text('Images have been converted to a PDF'),
    duration: const Duration(seconds: 2),
  );

  void removeImage() {
    setState(() {
      pickedImages.removeAt(selectedIndex);
      selectedIndex = -1;
    });
  }

  Future<void> pickImages() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result == null) {
      return;
    }
    setState(() {
      result.files.forEach((file) {
        pickedImages.add(File(file.path));
      });
    });
  }

  void moveSelectedImageUp() {
    if (selectedIndex <= 0) {
      return;
    }
    setState(() {
      final selectedItem = pickedImages[selectedIndex];
      pickedImages.removeAt(selectedIndex);
      pickedImages.insert(selectedIndex - 1, selectedItem);
      selectedIndex = selectedIndex - 1;
    });
  }

  void moveSelectedImageDown() {
    if (selectedIndex < 0 || selectedIndex == pickedImages.length - 1) {
      return;
    }
    setState(() {
      final selectedItem = pickedImages[selectedIndex];
      pickedImages.removeAt(selectedIndex);
      pickedImages.insert(selectedIndex + 1, selectedItem);
      selectedIndex = selectedIndex + 1;
    });
  }

  pw.Document createPdfFromImages() {
    final pdf = pw.Document();
    pickedImages.forEach((image) {
      pdf.addPage(pw.Page(
        build: (c) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Image(
                pw.MemoryImage(image.readAsBytesSync()),
                fit: pw.BoxFit.scaleDown,
              ),
            ),
          );
        },
      ));
    });
    return pdf;
  }

  Future<void> convertToPdf() async {
    final pdf = createPdfFromImages();
    String outputPath;
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        outputPath = await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOADS);
        outputPath += '/converted.pdf';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(permissionError);
        return;
      }
    } else {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'converted.pdf',
      );
    }

    if (outputPath == null) {
      return;
    }

    if (!outputPath.endsWith('.pdf')) {
      outputPath = outputPath + '.pdf';
    }

    File(outputPath).writeAsBytesSync(await pdf.save());

    setState(() {
      pickedImages.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(conversionSuccessful);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF converter'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      iconSize: 30.0,
                      icon: const Icon(Icons.add),
                      onPressed: pickImages,
                      tooltip: 'Add images for conversion',
                    ),
                    IconButton(
                      iconSize: 30.0,
                      icon: const Icon(Icons.remove),
                      onPressed: selectedIndex == -1 ? null : removeImage,
                      tooltip: 'Remove the image',
                    ),
                    IconButton(
                      iconSize: 30.0,
                      icon: const Icon(Icons.arrow_upward),
                      onPressed:
                          selectedIndex == -1 ? null : moveSelectedImageUp,
                      tooltip: 'Move selected image up',
                    ),
                    IconButton(
                      iconSize: 30.0,
                      icon: const Icon(Icons.arrow_downward),
                      onPressed:
                          selectedIndex == -1 ? null : moveSelectedImageDown,
                      tooltip: 'Move selected image down',
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: pickedImages.length,
                    itemBuilder: (context, index) => Container(
                      color: selectedIndex == index
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                      child: ListTile(
                        title: Text(pickedImages[index].path),
                        onTap: () {
                          setState(() {
                            if (selectedIndex == index) {
                              selectedIndex = -1;
                            } else {
                              selectedIndex = index;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedIndex >= 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 10,
                  top: 10,
                  bottom: 10,
                ),
                child: Image.file(pickedImages[selectedIndex]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickedImages.isEmpty ? null : convertToPdf,
        tooltip: 'Convert picked images to PDF',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
