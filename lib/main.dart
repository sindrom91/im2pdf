import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:pdf/widgets.dart' as pw;

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
      home: MyHomePage(title: 'Image to PDF converter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<File> pickedImages = [];
  int selectedIndex = -1;

  Future<void> pickImages() async {
    final files = await FileSelectorPlatform.instance.openFiles(
        initialDirectory: await PathProviderLinux().getDownloadsPath());
    setState(() {
      files.forEach((file) {
        pickedImages.add(File(file.path));
      });
    });
  }

  Future<void> convertToPdf() async {
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

    final outputFile = File(
      await FileSelectorPlatform.instance.getSavePath(
        initialDirectory: await PathProviderLinux().getDownloadsPath(),
      ),
    );
    outputFile.writeAsBytes(await pdf.save());

    setState(() {
      pickedImages.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Images have been converted to a PDF'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: () {
                        if (selectedIndex <= 0) {
                          return;
                        }
                        setState(() {
                          final selectedItem = pickedImages[selectedIndex];
                          pickedImages.removeAt(selectedIndex);
                          pickedImages.insert(selectedIndex - 1, selectedItem);
                          selectedIndex = selectedIndex - 1;
                        });
                      },
                      tooltip: 'Move selected image up',
                    ),
                    IconButton(
                      iconSize: 30.0,
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: () {
                        if (selectedIndex < 0 ||
                            selectedIndex == pickedImages.length - 1) {
                          return;
                        }
                        setState(() {
                          final selectedItem = pickedImages[selectedIndex];
                          pickedImages.removeAt(selectedIndex);
                          pickedImages.insert(selectedIndex + 1, selectedItem);
                          selectedIndex = selectedIndex + 1;
                        });
                      },
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
