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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              icon: const Icon(Icons.compare_arrows), onPressed: convertToPdf),
        ],
      ),
      body: ListView.builder(
        itemCount: pickedImages.length,
        itemBuilder: (context, index) => Text(pickedImages[index].path),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImages,
        tooltip: 'Add files for conversion',
        child: Icon(Icons.add),
      ),
    );
  }
}
