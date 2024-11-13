import 'dart:io';

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

class FileList {
  final List<File> l = [];
  var selectedElement = -1;

  FileList();

  int get length => l.length;
  bool get isEmpty => length == 0;
  File operator [](int index) => l[index];
  void operator []=(int index, File value) => l[index] = value;
  void add(File f) => l.add(f);

  bool canMoveUp() => selectedElement > 0;
  bool canMoveDown() => selectedElement != l.length -1 && selectedElement != -1;
  bool isAnythingSelected() => selectedElement != -1;
  bool isElementSelected(int i) => selectedElement == i;
  void selectElement(int i) => selectedElement = i;
  void unselectElement() => selectedElement = -1;

  void moveUp() {
    if (selectedElement <= 0) {
      return;
    }
    swap(selectedElement, selectedElement - 1);
    selectedElement = selectedElement - 1;
  }

  void moveDown() {
    if (selectedElement < 0 || selectedElement == l.length - 1) {
      return;
    }
    swap(selectedElement, selectedElement + 1);
    selectedElement = selectedElement + 1;
  }

  void swap(int index1, int index2) {
    var length = l.length;
    RangeError.checkValidIndex(index1, l, "index1", length);
    RangeError.checkValidIndex(index2, l, "index2", length);
    if (index1 != index2) {
      var tmp1 = l[index1];
      l[index1] = l[index2];
      l[index2] = tmp1;
    }
  }

  File getSelectedFile() => this[selectedElement];

  void removeSelected() {
    l.removeAt(selectedElement);
    selectedElement = -1;
  }

  void clear() {
    l.clear();
    selectedElement = -1;
  }

  void forEach(void action(File element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      action(this[i]);
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var images = FileList();

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
      images.removeSelected();
    });
  }

  Future<void> pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result == null) {
      return;
    }
    setState(() {
      result.files.forEach((file) {
        if (file.path != null) {
          images.add(File(file.path as String));
        }
      });
    });
  }

  void moveSelectedImageUp() {
    setState(() {
      images.moveUp();
    });
  }

  void moveSelectedImageDown() {
    setState(() {
      images.moveDown();
    });
  }

  pw.Document createPdfFromImages() {
    final pdf = pw.Document();
    images.forEach((image) {
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
    final pdfBytes = await pdf.save();
    String? outputPath;
    if (Platform.isAndroid) {
      if (!await Permission.storage.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(permissionError);
        return;
      }
    }

    outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'converted.pdf',
      type: FileType.custom,
      allowedExtensions: ["pdf"],
      bytes: pdfBytes,
    );

    if (outputPath == null) {
      return;
    }

    if (!Platform.isAndroid) File(outputPath).writeAsBytesSync(pdfBytes);

    setState(() {
      images.clear();
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
                      onPressed: images.isAnythingSelected() ? removeImage : null,
                      tooltip: 'Remove the image',
                    ),
                    IconButton(
                      iconSize: 30.0,
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: images.canMoveUp() ? moveSelectedImageUp : null,
                      tooltip: 'Move selected image up',
                    ),
                    IconButton(
                      iconSize: 30.0,
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: images.canMoveDown() ? moveSelectedImageDown : null,
                      tooltip: 'Move selected image down',
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: images.length,
                    itemBuilder: (context, index) => Container(
                      color: images.isElementSelected(index)
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                      child: ListTile(
                        title: Text(images[index].path),
                        onTap: () {
                          setState(() {
                            if (images.isElementSelected(index)) {
                              images.unselectElement();
                            } else {
                              images.selectElement(index);
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
          if (images.isAnythingSelected())
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 10,
                  top: 10,
                  bottom: 10,
                ),
                child: Image.file(images.getSelectedFile()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: !images.isEmpty ? convertToPdf : null,
        tooltip: 'Convert picked images to PDF',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
